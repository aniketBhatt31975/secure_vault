# Database Code Generation — Hive vs Isar vs Drift

## The core question: what does a code generator actually do?

When you store an object in a database, the DB engine doesn't understand Dart classes.
It only understands bytes. Someone has to convert your `NoteModel` object into bytes
(serialise) and bytes back into a `NoteModel` (deserialise).

A code generator reads your annotated Dart class and **writes that conversion code for you**.
Without it, you write the conversion code yourself.

The critical difference between Hive and Isar is:
- **Hive** — conversion code is pure Dart. You can write it manually.
- **Isar** — conversion code compiles into a binary schema consumed by a native Rust engine. You cannot write this manually.

---

## HIVE

### How Hive stores data

Hive is a pure-Dart key-value store. It stores everything as binary (using its own
`BinaryWriter`). To store a custom Dart object, Hive needs a `TypeAdapter` — a class
that knows how to convert your object to/from binary.

### WITH generator

You annotate your model:

```dart
import 'package:hive/hive.dart';

part 'note_model.g.dart'; // generator writes this file

@HiveType(typeId: 0)
class NoteModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String encryptedContent;

  @HiveField(3)
  final int createdAtMs; // stored as int, not DateTime — Hive doesn't know DateTime

  NoteModel({
    required this.id,
    required this.title,
    required this.encryptedContent,
    required this.createdAtMs,
  });
}
```

Run `flutter pub run build_runner build` and the generator produces `note_model.g.dart`:

```dart
// note_model.g.dart  — GENERATED, do not edit
class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 0;

  @override
  NoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteModel(
      id:               fields[0] as String,
      title:            fields[1] as String,
      encryptedContent: fields[2] as String,
      createdAtMs:      fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer
      ..writeByte(4)       // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.encryptedContent)
      ..writeByte(3)
      ..write(obj.createdAtMs);
  }
}
```

### WITHOUT generator (what we do in this project)

You skip the annotations and write the adapter yourself:

```dart
// note_model.dart — no annotations needed
class NoteModel {
  final String id;
  final String title;
  final String encryptedContent;
  final int createdAtMs;

  NoteModel({
    required this.id,
    required this.title,
    required this.encryptedContent,
    required this.createdAtMs,
  });
}
```

```dart
// note_model_adapter.dart — you write this once, manually
import 'package:hive/hive.dart';
import 'note_model.dart';

class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 0;

  @override
  NoteModel read(BinaryReader reader) {
    return NoteModel(
      id:               reader.readString(),
      title:            reader.readString(),
      encryptedContent: reader.readString(),
      createdAtMs:      reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.encryptedContent);
    writer.writeInt(obj.createdAtMs);
  }
}
```

Register once at app startup, before any box is opened:

```dart
// main.dart or injection_container.dart
await Hive.initFlutter();
Hive.registerAdapter(NoteModelAdapter());
final box = await Hive.openBox<NoteModel>('notes');
```

### What changes if you add a new field?

With generator — add `@HiveField(4)` and re-run `build_runner`.
Without generator — add the field to the model and update `read()`/`write()` manually.

The field index (0, 1, 2...) is critical. Hive uses it for forward/backward
compatibility. Never reorder or reuse indexes — only append new ones.

```dart
// CORRECT — append new field at the end
void write(BinaryWriter writer, NoteModel obj) {
  writer.writeString(obj.id);            // index 0
  writer.writeString(obj.title);         // index 1
  writer.writeString(obj.encryptedContent); // index 2
  writer.writeInt(obj.createdAtMs);      // index 3
  writer.writeString(obj.tags);          // index 4 — NEW, safe to append
}

// WRONG — reordered fields, existing data becomes corrupted
void write(BinaryWriter writer, NoteModel obj) {
  writer.writeString(obj.tags);          // was index 0 (id) — CORRUPTS existing data
  writer.writeString(obj.id);
  ...
}
```

---

## ISAR

### How Isar works internally

Isar is backed by a native database engine written in Rust (via ISAR C library).
The native layer is compiled into platform binaries — the `.so` on Android,
`.dylib` on iOS/macOS. This native layer is extremely fast but it has a strict
requirement: it needs a **compiled binary schema** before it can open a collection.

The binary schema is not a Dart file. It is a binary descriptor that the native
Rust engine reads to understand your collection's structure — field names, types,
indexes, links. Think of it like a table definition in SQL, but compiled to binary
and embedded in your app.

### WITH generator

```dart
import 'package:isar/isar.dart';

part 'note_model.g.dart'; // generator produces this

@collection
class NoteModel {
  Id id = Isar.autoIncrement;

  late String title;

  late String encryptedContent;

  @Index(type: IndexType.value)
  late String tag;

  late int createdAtMs;
}
```

Run `build_runner` and `note_model.g.dart` is produced. It contains:

1. **The binary schema** — a `Uint8List` that the native engine reads
2. **Query extension methods** — e.g. `where().titleEqualTo('x').findAll()`
3. **Schema hash** — used to detect breaking changes at runtime

```dart
// Excerpt from generated file (simplified)
const IsarGeneratedSchema noteModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'NoteModel',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'title',            type: IsarType.string),
      IsarPropertySchema(name: 'encryptedContent', type: IsarType.string),
      IsarPropertySchema(name: 'tag',              type: IsarType.string),
      IsarPropertySchema(name: 'createdAtMs',      type: IsarType.long),
    ],
    indexes: [
      IsarIndexSchema(name: 'tag', properties: ['tag'], unique: false, hash: false),
    ],
  ),
  converter: IsarObjectConverter<void, NoteModel>(
    serialize:   serializeNoteModel,
    deserialize: deserializeNoteModel,
  ),
  embeddedSchemas: [],
);
```

Without this generated schema object, `Isar.open()` has nothing to pass to the
native layer → crash on startup.

### WITHOUT generator — why there is NO manual fallback

```dart
// You cannot replicate this manually:
final isar = await Isar.open(
  [NoteModelSchema], // <-- this IsarGeneratedSchema MUST be generated
);
```

`NoteModelSchema` is a `IsarGeneratedSchema` — a complex object containing a
serialised binary descriptor. There is no API to construct this at runtime from
plain Dart. The Isar package intentionally has no public constructor for it.

Even if you tried to write the binary bytes manually, you would need to:
1. Match Isar's internal binary schema format exactly (undocumented)
2. Write the query extension methods with the correct Isar low-level FFI calls
3. Match the schema hash algorithm exactly (or it rejects your schema)

This is not feasible manually. The generator exists because it has to.

### What this means for our project

```dart
// lib/features/notes/data/datasources/local/isar_datasource.dart
// This file exists as a STUB. It cannot be implemented until
// isar_generator conflict with drift_dev is resolved (expected in Isar v4).

class IsarDatasource implements DbInterface {
  @override
  Future<List<NoteModel>> getNotes() {
    throw UnimplementedError('Isar schema generation blocked by analyzer conflict.');
  }
  // ...
}
```

The DB abstraction layer (`DbInterface`) means this is a one-file swap.
When Isar v4 ships, `IsarDatasource` gets implemented and the DI container
changes one line. Nothing else moves.

---

## DRIFT

Drift (formerly Moor) is the most mature option. It generates type-safe query
code from table definitions.

### WITH generator (our setup — drift_dev is installed)

```dart
// lib/features/notes/data/datasources/local/drift_datasource.dart

import 'package:drift/drift.dart';

part 'drift_datasource.g.dart'; // generated

class Notes extends Table {
  TextColumn get id               => text()();
  TextColumn get title            => text()();
  TextColumn get encryptedContent => text()();
  IntColumn  get createdAtMs      => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}
```

Run `build_runner` → generates:
- `_$AppDatabase` base class
- `Note` data class (the row object)
- `NoteCompanion` for inserts/updates
- Type-safe query methods

```dart
// Usage after generation
Future<List<Note>> getAllNotes() => select(notes).get();

Future<void> insertNote(NotesCompanion entry) =>
    into(notes).insert(entry);

Future<List<Note>> searchNotes(String query) =>
    (select(notes)..where((n) => n.title.contains(query))).get();
```

---

## Side by side comparison

| | Hive | Isar | Drift |
|---|---|---|---|
| Generator need | Optional | Mandatory | Mandatory |
| Without generator | Write TypeAdapter manually | Not possible | Not possible |
| Generator conflict | hive_generator conflicts with drift_dev | isar_generator conflicts with drift_dev | drift_dev works fine |
| Our status | Manual adapter — fully working | Stub — unblocked on Isar v4 | Fully working with drift_dev |
| Storage type | Key-value binary box | Embedded NoSQL (Rust native) | SQLite (relational) |
| Query capability | Basic (get by key) | Advanced (indexes, links, full-text) | Full SQL via type-safe Dart API |
| Best for | Simple fast storage | Complex queries, reactive streams | Relational data, migrations |
