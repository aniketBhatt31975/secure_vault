# drift_datasource.dart — Interview Explainer

## What this file does in one sentence

It defines the SQLite database schema using Drift, wires it to a physical file on disk,
and implements every database operation the app needs — all in a way that's fully
swappable behind the `DbInterface` contract.

---

## File structure at a glance

```
drift_datasource.dart
│
├── part 'drift_datasource.g.dart'     ← code generator writes this
│
├── NotesTable                         ← schema: what the SQL table looks like
├── AppDatabase                        ← the database itself
├── _openConnection()                  ← where the .db file lives on disk
│
└── DriftDatasource                    ← implements DbInterface (CRUD operations)
    ├── getNotes()
    ├── getNoteById()
    ├── insertNote()
    ├── updateNote()
    ├── deleteNote()
    ├── searchNotes()
    ├── _rowToModel()                  ← DB row → NoteModel
    └── _modelToCompanion()            ← NoteModel → DB row
```

---

## Section 1 — The `part` directive

```dart
part 'drift_datasource.g.dart';
```

**What it does:** Tells Dart that `drift_datasource.g.dart` is part of the same
library as this file. The generator writes that file when you run `build_runner`.

**What the generated file contains:**
- `_$AppDatabase` — the base class `AppDatabase extends` from
- `NotesTableData` — a plain Dart class representing one row
- `NotesTableCompanion` — used for inserts and updates
- `$NotesTableTable` — the query-builder object (`_db.notesTable`)

**Interview answer if asked "why `part` and not `import`?"**

> `part` makes the generated file a member of the same library, so it can access
> private members and extend internal generated base classes like `_$AppDatabase`.
> A normal `import` can't do that.

---

## Section 2 — `NotesTable` — the schema definition

```dart
class NotesTable extends Table {
  @override
  String get tableName => 'notes';

  TextColumn get id               => text()();
  TextColumn get title            => text()();
  TextColumn get encryptedContent => text().named('encrypted_content')();
  IntColumn  get createdAt        => integer().named('created_at')();
  IntColumn  get updatedAt        => integer().named('updated_at')();
  BoolColumn get isPinned         => boolean().named('is_pinned').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### What each part means

**`extends Table`** — Drift uses this class as a schema blueprint, not a runtime object.
You never instantiate `NotesTable`. The generator reads it at build time and produces
the actual SQL `CREATE TABLE` statement.

**`text()()` — why two `()`?**

```dart
TextColumn get id => text()();
//                   ^^^^ ^^
//                   (1)  (2)
// (1) text() returns a ColumnBuilder
// (2) calling it () finalises the column and returns TextColumn
```

This is Drift's builder pattern. You can chain modifiers before the final call:

```dart
text().named('encrypted_content')()
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
//    sets the SQL column name to 'encrypted_content'
//    (Dart field is camelCase; SQL column is snake_case)
```

**`.named('encrypted_content')`** — Dart property names are camelCase but SQL
convention is snake_case. `.named()` sets the actual column name in SQL without
changing the Dart field name. So in SQL: `encrypted_content`, in Dart: `encryptedContent`.

**`withDefault(const Constant(false))`** — sets a SQL-level DEFAULT. If you insert
a row without specifying `isPinned`, the DB fills it in as `false` automatically.

**`Set<Column> get primaryKey => {id}`** — defines the primary key. Drift generates
a UNIQUE constraint on this column. No `@PrimaryKey` annotation needed — just override
this getter.

**`tableName`** — without this override, Drift would name the table `notes_table`
(the class name in snake_case). We override to `'notes'` for a cleaner name.

---

## Section 3 — `AppDatabase`

```dart
@DriftDatabase(tables: [NotesTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}
```

**`@DriftDatabase(tables: [NotesTable])`** — tells the generator which tables belong
to this database. For every table listed here, the generator:
- adds a getter (e.g. `notesTable`) to `_$AppDatabase`
- generates the `CREATE TABLE` SQL
- generates `NotesTableData` and `NotesTableCompanion`

**`extends _$AppDatabase`** — `_$AppDatabase` is the generated base class. It contains
all the query infrastructure. You extend it, providing the connection.

**`schemaVersion => 1`** — critical for migrations. If you bump this to `2` later,
Drift calls your `migration` strategy to ALTER the table. Without versioning, you
can't safely change the schema on existing user devices.

---

## Section 4 — `_openConnection()`

```dart
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'secure_vault.db'));
    return NativeDatabase.createInBackground(file);
  });
}
```

**`LazyDatabase`** — wraps the real database opening in a lazy future. The database
file is not opened until the first query runs. This keeps app startup fast — the DB
connection is deferred until actually needed.

**`getApplicationDocumentsDirectory()`** — returns the OS-appropriate private
documents directory:
```
Android  →  /data/data/com.example.secure_vault/app_flutter/
iOS      →  /var/mobile/.../Documents/
```
This directory is sandboxed — other apps cannot read it.

**`NativeDatabase.createInBackground(file)`** — opens SQLite on a background
isolate so DB operations never block the UI thread. This is one reason Drift is
preferred over raw `sqflite` for production apps.

---

## Section 5 — `DriftDatasource` implements `DbInterface`

```dart
class DriftDatasource implements DbInterface {
  late AppDatabase _db;

  @override
  Future<void> init() async {
    _db = AppDatabase();
  }
```

`implements DbInterface` is the key line. The entire rest of the app talks to
`DbInterface` — it has no idea Drift exists. Swap this to `HiveDatasource` in DI
and Drift never runs.

`late AppDatabase _db` — declared `late` because the DB is created in `init()`,
not the constructor. `init()` is called by the DI container before any operations run.

---

## Section 6 — CRUD operations

### `getNotes()`

```dart
final rows = await (_db.select(_db.notesTable)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
    .get();
```

This is Drift's type-safe query API. Equivalent SQL:
```sql
SELECT * FROM notes ORDER BY updated_at DESC;
```

`..orderBy` uses the cascade operator — adds ordering to the select statement
without breaking the chain. `OrderingTerm.desc(t.updatedAt)` compiles to `DESC`.

The compiler knows `t.updatedAt` is an `IntColumn`. If you misspell it, you get a
compile error, not a runtime crash. **This is Drift's main advantage over raw SQL.**

---

### `getNoteById()`

```dart
final row = await (_db.select(_db.notesTable)
      ..where((t) => t.id.equals(id)))
    .getSingleOrNull();
```

Equivalent SQL:
```sql
SELECT * FROM notes WHERE id = ? LIMIT 1;
```

`getSingleOrNull()` — returns `null` if not found, throws if more than one row matches.
`getSingle()` would throw on zero results. Choosing the right one prevents silent bugs.

---

### `insertNote()`

```dart
await _db.into(_db.notesTable).insert(_modelToCompanion(note));
```

Equivalent SQL:
```sql
INSERT INTO notes (id, title, encrypted_content, ...) VALUES (?, ?, ?, ...);
```

Notice we pass a `NotesTableCompanion`, not a `NotesTableData`. This is intentional —
see Section 8 for why.

---

### `updateNote()`

```dart
await (_db.update(_db.notesTable)
      ..where((t) => t.id.equals(note.id)))
    .write(_modelToCompanion(note));
```

Equivalent SQL:
```sql
UPDATE notes SET title = ?, encrypted_content = ?, ... WHERE id = ?;
```

The cascade `..where` narrows which rows to update before `.write()` executes.
Without `..where`, this would update every row — a common raw SQL bug that Drift
makes harder to write accidentally.

---

### `deleteNote()`

```dart
await (_db.delete(_db.notesTable)..where((t) => t.id.equals(id))).go();
```

Equivalent SQL:
```sql
DELETE FROM notes WHERE id = ?;
```

`.go()` executes the delete. Same cascade pattern — filter first, then execute.

---

### `searchNotes()`

```dart
..where((t) => t.title.contains(query))
```

Equivalent SQL:
```sql
WHERE title LIKE '%query%'
```

Drift's `.contains()` compiles to a SQL `LIKE` expression. Type-safe — you can only
call `.contains()` on a `TextColumn`, not on an `IntColumn`.

> **Interview note:** Search runs against encrypted titles in our app. Since content
> is encrypted at rest, SQL LIKE won't match plaintext. The `NoteRepositoryImpl`
> handles this by decrypting all results in memory. For large datasets, a separate
> plaintext search index would be the production solution.

---

## Section 7 — `_rowToModel()` mapper

```dart
NoteModel _rowToModel(NotesTableData row) => NoteModel(
      id: row.id,
      title: row.title,
      encryptedContent: row.encryptedContent,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      isPinned: row.isPinned,
    );
```

`NotesTableData` is generated — it's a plain Dart class with one field per column.
This mapper converts it to `NoteModel` (our data layer type) which extends `Note`
(our domain entity). The conversion happens here, in the datasource — not in the
domain layer, which must stay clean.

`DateTime.fromMillisecondsSinceEpoch(row.createdAt)` — Drift doesn't have a native
DateTime column type in all backends. We store timestamps as milliseconds (Int) and
convert here on read.

---

## Section 8 — `_modelToCompanion()` — why Companion?

```dart
NotesTableCompanion _modelToCompanion(NoteModel note) => NotesTableCompanion(
      id:    Value(note.id),
      title: Value(note.title),
      ...
    );
```

**Why not just use `NotesTableData` for inserts?**

`NotesTableData` represents a complete, existing row. Every field is required.
`NotesTableCompanion` represents a partial row — each field is wrapped in `Value<T>`,
which can be:

```dart
Value(actualValue)   // include this field in the INSERT/UPDATE
Value.absent()       // omit this field — use DB default or don't update it
```

This matters for partial updates:

```dart
// Update only the title — leave all other columns untouched
NotesTableCompanion(
  title: Value('New Title'),
  // all others are Value.absent() by default
)
```

With `NotesTableData`, you'd have to provide every field even if you only changed one.
Companion gives you surgical updates.

---

## Section 9 — Error handling pattern

```dart
try {
  // ... drift operation
} catch (e) {
  throw StorageException('DriftGet failed: $e');
}
```

Every public method catches all exceptions and rethrows as `StorageException` —
our app's typed error. This means:
- The repository impl only needs to catch `StorageException`
- Cubits only see domain-level failures
- No `DriftException` or `SqliteException` leaks past the data layer

This is the **boundary translation** pattern — translate infrastructure errors into
app-level errors at the layer boundary.

---

## Summary table for interview

| Concept | What it is | Why it matters |
|---|---|---|
| `part 'drift_datasource.g.dart'` | Links generated file to this library | Gives access to generated base classes |
| `NotesTable extends Table` | Schema blueprint | Generates `CREATE TABLE` SQL at build time |
| `text().named('x')()` | Column builder chain | Sets Dart name vs SQL name separately |
| `schemaVersion` | Int on AppDatabase | Enables safe migrations on user devices |
| `LazyDatabase` | Deferred DB opening | Keeps startup fast; opens on first query |
| `NativeDatabase.createInBackground` | Opens SQLite on background isolate | UI thread never blocks on DB I/O |
| `implements DbInterface` | Contract | Makes Drift swappable — DI injects the impl |
| `getSingleOrNull()` vs `getSingle()` | Null-safe vs throwing | Explicit about expected row count |
| `NotesTableCompanion` vs `NotesTableData` | Partial vs full row | Enables partial updates without overwriting |
| `Value(x)` / `Value.absent()` | Column presence wrapper | Controls which fields appear in SQL statement |
| `StorageException` rethrow | Error boundary | Prevents Drift types leaking into domain/presentation |
