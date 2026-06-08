# Secure Vault — Interview Q&A

All answers are grounded in the actual code of this project.

---

## Architecture & Design

### 1. Why Clean Architecture?

Clean Architecture separates the codebase into three layers:

- **Domain** — pure business logic: `Note` entity, `NoteRepository` interface, use cases (`GetNotes`, `CreateNote`, etc.). No Flutter imports.
- **Data** — implementation detail: `HiveDatasource`, `NoteModel`, `NoteRepositoryImpl`. Knows about Hive, SQLite, serialization.
- **Presentation** — UI: `NotesCubit`, `NotesListScreen`, widgets.

**Problem it solves:** The domain layer has zero knowledge of Hive or Flutter. You can swap Hive for Drift or SQLite by changing only the data layer — the Cubit, Use Cases, and entities are untouched. It also makes unit-testing Use Cases trivial since they depend only on the abstract `NoteRepository`.

---

### 2. What is the Dependency Rule?

Inner layers must not import from outer layers.

```
Presentation → Domain ← Data
```

In this project:
- `NoteRepository` (domain) is an **abstract class** — it has no import from `data/`.
- `NoteRepositoryImpl` (data) implements it and imports from domain.
- `NotesCubit` (presentation) depends on `NoteRepository` interface, not on `HiveDatasource`.

This means `domain/` can be compiled and tested with zero knowledge of Flutter or any storage library.

---

### 3. What are Use Cases and why not call the repository directly from the Cubit?

A Use Case is a single-responsibility class wrapping one business operation. Example from the project:

```dart
// lib/features/notes/domain/usecases/get_notes.dart
class GetNotes {
  final NoteRepository repository;
  GetNotes(this.repository);

  Future<List<Note>> call() => repository.getNotes();
}
```

**Why not call the repository directly?**
- Each Use Case can add business logic (validation, transformation) without bloating the Cubit.
- Use Cases are independently testable — mock just `NoteRepository`, test just `GetNotes`.
- The Cubit stays thin: it orchestrates state, not business logic.
- As the app grows, a Use Case like `CreateNote` could validate title length, enforce limits, etc., without touching the Cubit or data layer.

---

### 4. Why `Note` entity AND `NoteModel`?

| | `Note` (entity) | `NoteModel` (data model) |
|---|---|---|
| Layer | Domain | Data |
| Purpose | Pure business object | Serialization / storage contract |
| Imports | `equatable` only | Hive/Drift serialization logic |
| Methods | `copyWith` | `fromMap`, `toMap`, `fromEntity`, `toEntity` |

`NoteModel.fromMap` knows that `is_pinned` is stored as an integer (`0`/`1`) in the database — that's a storage detail the domain shouldn't care about. Keeping them separate means you can change the DB schema (e.g., rename `encrypted_content` column) without touching the domain entity.

In this project, `NoteModel extends Note` for convenience (avoids duplicating fields), but conceptually they represent different concerns.

---

## State Management (BLoC/Cubit)

### 5. Difference between BLoC and Cubit — why Cubit here?

| | BLoC | Cubit |
|---|---|---|
| Input | Events (classes) | Direct method calls |
| Boilerplate | High (Event class per action) | Low |
| Traceability | Full event history | Less granular |

**This project uses Cubit** because the operations (load, create, update, delete, search) map cleanly to direct method calls with no complex event transformation needed. Example:

```dart
// Simple method call, no event class required
await cubit.createNote(title: 'My Note', content: '...');
```

If you needed complex event pipelines (debounce, switchMap, concurrency control between events), BLoC's event streams would be the right choice.

---

### 6. What is `Equatable` used for?

`Equatable` overrides `==` and `hashCode` using a `props` list, enabling **value equality** instead of reference equality.

```dart
class NotesLoaded extends NotesState {
  final List<Note> notes;
  const NotesLoaded(this.notes);

  @override
  List<Object?> get props => [notes]; // equality based on notes list
}
```

Without `Equatable`, `NotesLoaded([noteA]) == NotesLoaded([noteA])` would be `false` (different object references). BlocBuilder uses `==` to decide whether to rebuild — so without value equality, **every emit would trigger a rebuild** even if the data is identical, causing unnecessary widget rebuilds.

---

### 7. How are loading/success/error states handled?

`NotesState` is an abstract class with four concrete subclasses:

```dart
abstract class NotesState extends Equatable { ... }

class NotesInitial extends NotesState {}    // app just launched
class NotesLoading extends NotesState {}    // async op in progress
class NotesLoaded extends NotesState {      // data ready
  final List<Note> notes;
}
class NotesError extends NotesState {       // something failed
  final String message;
}
```

In the Cubit:
```dart
Future<void> loadNotes() async {
  emit(NotesLoading());              // show spinner
  final notes = await _getNotes.call();
  emit(NotesLoaded(notes));          // show list
  // catch block: emit(NotesError(...))
}
```

The UI uses `BlocBuilder` to switch UI based on state type — spinner for `NotesLoading`, list for `NotesLoaded`, error message for `NotesError`.

---

### 8. How do you prevent unnecessary BlocBuilder rebuilds?

Two mechanisms:

1. **`Equatable` on states** — `BlocBuilder` compares previous and new state with `==`. If equal, no rebuild. This project uses `Equatable` on all states.

2. **`buildWhen`** — filter rebuilds to specific state transitions:
   ```dart
   BlocBuilder<NotesCubit, NotesState>(
     buildWhen: (prev, curr) => curr is NotesLoaded,
     builder: (context, state) => ...,
   )
   ```

Without these, emitting the same data twice would still rebuild the widget tree unnecessarily.

---

## Dependency Injection

### 9. Why `get_it`? `registerFactory` vs `registerSingleton`?

`get_it` is a **Service Locator** — a global registry you query by type:

```dart
final sl = GetIt.instance;
sl<GetNotes>() // returns the registered instance
```

| Method | Behaviour |
|---|---|
| `registerSingleton` | Creates the instance immediately; same instance always returned |
| `registerLazySingleton` | Creates on first `sl()` call; same instance after that |
| `registerFactory` | Creates a **new** instance on every `sl()` call |

In this project:
```dart
sl.registerSingleton<DbInterface>(db);           // DB opened once, shared everywhere
sl.registerLazySingleton(() => GetNotes(sl()));  // created on first use, then reused
```

`DbInterface` is a regular singleton because the database must be initialized before registration. Use Cases are lazy singletons — stateless, safe to share, no need for multiple instances.

---

### 10. Service Locator vs Constructor Injection

| | Service Locator (`get_it`) | Constructor Injection |
|---|---|---|
| Dependencies | Pulled from global registry | Pushed in at instantiation |
| Testability | Must pre-populate `sl` in tests | Pass mocks directly in constructor |
| Visibility | Hidden dependencies | Explicit, visible in constructor |

Constructor injection is generally preferred in pure DI but requires a DI framework (like `injectable`). `get_it` as a Service Locator is simpler to set up for Flutter apps and is the community standard. The tradeoff: dependencies aren't visible from the constructor signature — you must check `injection_container.dart` to know what a class depends on.

---

## Local Storage & Encryption

### 11. Drift vs Hive vs Isar — why three implementations?

The project defines a `DbInterface` abstraction:

```dart
abstract class DbInterface {
  Future<void> init();
  Future<List<NoteModel>> getNotes();
  Future<NoteModel?> getNoteById(String id);
  Future<void> insertNote(NoteModel note);
  Future<void> updateNote(NoteModel note);
  Future<void> deleteNote(String id);
  Future<List<NoteModel>> searchNotes(String query);
  Future<void> close();
}
```

Three implementations exist (`HiveDatasource`, `DriftDatasource`, `IsarDatasource`) to compare tradeoffs:

| | Hive | Drift (SQLite) | Isar |
|---|---|---|---|
| Type | Key-value NoSQL | Relational SQL | NoSQL (object store) |
| Query power | Basic | Full SQL | Rich but proprietary |
| Schema | Schemaless | Typed + migrations | Typed |
| Code gen | Not needed | Required (`drift_dev`) | Required |
| Best for | Simple fast storage | Complex queries/relations | High-perf object graphs |

Currently **Hive is active** (`injection_container.dart` line 21: `final DbInterface db = HiveDatasource()`). Switching to Drift requires only changing that one line — no Cubit or domain changes needed.

---

### 12. What encryption algorithm is used?

**AES-256-CBC with PKCS7 padding**, defined in `EncryptionConstants`:

```dart
static const int keyLength = 32;           // 256-bit key
static const int ivLength = 16;            // 128-bit IV
static const String algorithm = 'AES/CBC/PKCS7';
```

AES (Advanced Encryption Standard) is a symmetric block cipher. CBC (Cipher Block Chaining) XORs each plaintext block with the previous ciphertext block before encrypting, so identical plaintext blocks produce different ciphertext. PKCS7 padding ensures plaintext fits into 16-byte blocks.

---

### 13. Where is the encryption key stored? Security implications?

The key management strategy determines the app's real-world security. On mobile:

- **Ideal:** Store the key in the platform secure enclave — Android `Keystore` / iOS `Secure Enclave` via `flutter_secure_storage`. The key never leaves hardware.
- **Acceptable:** Derive the key from the user's PIN/password using PBKDF2 or Argon2. The key lives only in memory during the session.
- **Risky:** Hardcoding the key in code or storing it in `SharedPreferences`/`Hive` unprotected — an attacker with file system access can extract it.

In this project, encryption constants define the algorithm but key storage implementation should be verified in the datasource layer.

---

### 14. Why Drift over plain `sqflite`?

| | sqflite | Drift |
|---|---|---|
| Type safety | Raw `Map<String, dynamic>` | Generated typed classes |
| Queries | Raw SQL strings | Type-safe query builder |
| Migrations | Manual | `MigrationStrategy` with `Migrator` |
| Streams | Manual | Built-in reactive streams (`watchAll`) |
| Code gen | None | `drift_dev` + `build_runner` |

Drift catches SQL errors at **compile time** rather than runtime. For example, querying a non-existent column fails during `build_runner`, not when a user taps a button.

---

### 15. What is `drift_dev` + `build_runner`?

Drift uses code generation because Dart lacks runtime reflection (no `dart:mirrors` in Flutter). You define your schema in Dart:

```dart
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  // ...
}
```

Running `flutter pub run build_runner build` generates `drift_datasource.g.dart` — type-safe query methods, companion classes, and stream watchers. You never write raw SQL; the generated code does it for you and the compiler verifies it.

---

## Navigation

### 16. Why `go_router` over Navigator 2.0 directly?

Navigator 2.0 (the `Router` API) is powerful but extremely verbose — you must implement `RouterDelegate`, `RouteInformationParser`, and `BackButtonDispatcher` manually. `go_router` wraps this with a declarative, URL-based API:

```dart
final appRouter = GoRouter(
  initialLocation: RouteNames.notes,
  routes: [
    ShellRoute(/* shared Cubit scope */),
    GoRoute(path: '/notes/:id', builder: ...),
  ],
);
```

Benefits in this project:
- Path parameters (`/notes/:id`) extracted automatically via `state.pathParameters['id']`.
- Deep linking and web URL support out of the box.
- `ShellRoute` wraps child routes in a shared `BlocProvider<NotesCubit>`, so the Cubit persists across note list → detail → edit navigation without being recreated.

---

### 17. How do you handle auth-guarded routes?

`go_router` supports a `redirect` callback at the router or route level:

```dart
GoRouter(
  redirect: (context, state) {
    final isLoggedIn = /* check auth state */;
    if (!isLoggedIn && state.matchedLocation != '/login') {
      return '/login';
    }
    return null; // no redirect
  },
)
```

In the current project, the router goes directly to `RouteNames.notes` as `initialLocation` — auth guard can be added by listening to an `AuthCubit` state inside the `redirect` callback and redirecting to a lock/PIN screen if the vault is locked.

---

## Security

### 18. What is the threat model?

This app stores sensitive notes locally. The threats being defended against:

| Threat | Mitigation |
|---|---|
| Physical device access (unlocked) | App-level PIN/biometric lock |
| File system extraction (rooted/jailbroken device) | AES-256 encryption of note content at rest |
| Memory scraping | Minimize plaintext lifetime in memory |
| Shoulder surfing | Obscure content in recent apps screenshot |
| Backup extraction (Android) | `android:allowBackup="false"` |

The `encryptedContent` field on `Note` is named explicitly to signal that raw plaintext is never stored.

---

### 19. Why remove root detection?

Root detection was removed (per commit history) because:
- **False positives:** Many legitimate users (developers, power users) run rooted devices.
- **Bypassable:** Root detection can be trivially bypassed with tools like Magisk Hide — it provides security theater, not real protection.
- **Better alternative:** The actual defense is encryption. If content is AES-256 encrypted with a properly managed key, a rooted device cannot read the data without the key — regardless of root detection.

Root detection makes sense as a **defense-in-depth** measure for enterprise apps but is not a primary security control.

---

### 20. If the DB file is copied off the device, can an attacker read notes?

Depends on key management:

- The `encryptedContent` field in Hive is stored as a string — if it was encrypted before storage, the raw Hive box file contains ciphertext.
- AES-256-CBC with a properly managed key means the data is computationally infeasible to brute-force.
- **However:** If the encryption key is stored in the same Hive box or in `SharedPreferences` (unprotected), an attacker who copies the file system also gets the key — encryption is defeated.
- **Secure approach:** Key in Android Keystore / iOS Secure Enclave, or derived from user password (never persisted). Then copying the DB file yields only ciphertext with no accessible key.

---

## Testing

### 21. Why `mocktail` over `mockito`?

| | mockito | mocktail |
|---|---|---|
| Code gen | Requires `@GenerateMocks` + build_runner | None — uses generics |
| Null safety | Annotation-heavy workarounds | Native null-safe |
| Syntax | `when(mock.method()).thenReturn(...)` | Same but without codegen |

`mocktail` avoids the build step — you can create a mock with just:

```dart
class MockNoteRepository extends Mock implements NoteRepository {}
```

No `@GenerateMocks`, no `build_runner build` needed. Faster iteration in tests.

---

### 22. How would you unit test a Use Case?

```dart
class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  late GetNotes useCase;
  late MockNoteRepository mockRepo;

  setUp(() {
    mockRepo = MockNoteRepository();
    useCase = GetNotes(mockRepo);
  });

  test('returns notes from repository', () async {
    final notes = [Note(id: '1', title: 'Test', ...)];
    when(() => mockRepo.getNotes()).thenAnswer((_) async => notes);

    final result = await useCase.call();

    expect(result, notes);
    verify(() => mockRepo.getNotes()).called(1);
  });
}
```

The Use Case is a plain Dart class with no Flutter dependency — test runs without a device or emulator in milliseconds.

---

### 23. Unit vs Widget vs Integration tests in Flutter

| | Unit | Widget | Integration |
|---|---|---|---|
| Scope | Single class/function | Single widget | Full app |
| Dependencies | All mocked | Flutter test framework | Real device/emulator |
| Speed | Fastest (ms) | Fast (seconds) | Slowest (minutes) |
| Example | Test `GetNotes` use case | Test `NoteCard` renders title | Test create note flow end-to-end |

In this project: Unit tests cover Use Cases and Cubits (mock the repository). Widget tests verify `NoteCard` renders correctly. Integration tests would drive the full app through `flutter_driver` or `integration_test` package.

---

## Flutter / Dart

### 24. What is a `sealed class` in Dart and how does it help state handling?

A `sealed class` (Dart 3+) restricts which classes can implement or extend it to the **same file**. The compiler then knows all subtypes exhaustively and can enforce pattern-match completeness.

This project uses `abstract class NotesState` (Dart 2 style). With Dart 3 sealed classes you get:

```dart
sealed class NotesState {}
class NotesInitial extends NotesState {}
class NotesLoading extends NotesState {}
class NotesLoaded extends NotesState { final List<Note> notes; }
class NotesError extends NotesState { final String message; }

// Compiler enforces all cases are handled:
switch (state) {
  case NotesInitial() => ...,
  case NotesLoading() => ...,
  case NotesLoaded(:final notes) => ...,
  case NotesError(:final message) => ...,
}
// Forgetting any case → compile error, not a runtime bug
```

---

### 25. What does `path_provider` do?

`path_provider` provides platform-specific paths for file storage:

```dart
await getApplicationDocumentsDirectory() // iOS: NSDocumentDirectory
                                          // Android: app's files dir
await getTemporaryDirectory()             // temp/cache
```

Hive needs a writable directory to persist its box files. `Hive.initFlutter()` internally uses `path_provider` to find the correct location. Without it, Hive wouldn't know where to write on disk.

---

### 26. What is `uuid` used for and why not auto-increment IDs?

```dart
final note = Note(
  id: const Uuid().v4(),  // e.g. "550e8400-e29b-41d4-a716-446655440000"
  ...
);
```

**Why UUID over auto-increment:**

| | Auto-increment | UUID v4 |
|---|---|---|
| Generation | Requires DB round-trip | Generated locally, no DB call |
| Collision risk | None (sequential) | Negligible (2^122 space) |
| Offline-first | Problematic — need DB to get next ID | Works offline — ID is known before insert |
| Predictability | Sequential (enumerable) | Random — IDs can't be guessed |

Since this is an offline-first app with no server, UUIDs let the Cubit assign an ID **before** inserting into the database, which simplifies the flow and enables future sync without ID conflicts.

---

*Generated from actual project source code — answers reflect the real implementation.*
