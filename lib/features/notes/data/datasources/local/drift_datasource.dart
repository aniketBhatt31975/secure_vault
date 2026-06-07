import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../../core/errors/exceptions.dart';
import '../../models/note_model.dart';
import 'db_interface.dart';

part 'drift_datasource.g.dart';

// ---------------------------------------------------------------------------
// Table definition
// ---------------------------------------------------------------------------

class NotesTable extends Table {
  @override
  String get tableName => 'notes';

  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get encryptedContent => text().named('encrypted_content')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  BoolColumn get isPinned =>
      boolean().named('is_pinned').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [NotesTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static final _instance = AppDatabase._();

  factory AppDatabase() {
    return _instance;
  }

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'secure_vault.db'));
    return NativeDatabase.createInBackground(file);
  });
}

// ---------------------------------------------------------------------------
// Datasource implementation
// ---------------------------------------------------------------------------

class DriftDatasource implements DbInterface {
  late AppDatabase _db;

  @override
  Future<void> init() async {
    _db = AppDatabase();
  }

  @override
  Future<List<NoteModel>> getNotes() async {
    try {
      final rows =
          await (_db.select(_db.notesTable)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
      return rows.map(_rowToModel).toList();
    } catch (e) {
      throw StorageException('DriftGet failed: $e');
    }
  }

  @override
  Future<NoteModel?> getNoteById(String id) async {
    try {
      final row =
          await (_db.select(_db.notesTable)
            ..where((t) => t.id.equals(id))).getSingleOrNull();
      return row == null ? null : _rowToModel(row);
    } catch (e) {
      throw StorageException('DriftGetById failed: $e');
    }
  }

  @override
  Future<void> insertNote(NoteModel note) async {
    try {
      await _db.into(_db.notesTable).insert(_modelToCompanion(note));
    } catch (e) {
      throw StorageException('DriftInsert failed: $e');
    }
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    try {
      await (_db.update(_db.notesTable)
        ..where((t) => t.id.equals(note.id))).write(_modelToCompanion(note));
    } catch (e) {
      throw StorageException('DriftUpdate failed: $e');
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    try {
      await (_db.delete(_db.notesTable)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      throw StorageException('DriftDelete failed: $e');
    }
  }

  @override
  Future<List<NoteModel>> searchNotes(String query) async {
    try {
      final rows =
          await (_db.select(_db.notesTable)
            ..where((t) => t.title.contains(query))).get();
      return rows.map(_rowToModel).toList();
    } catch (e) {
      throw StorageException('DriftSearch failed: $e');
    }
  }

  @override
  Future<void> close() async => _db.close();

  // ---------------------------------------------------------------------------
  // Mappers
  // ---------------------------------------------------------------------------

  NoteModel _rowToModel(NotesTableData row) => NoteModel(
    id: row.id,
    title: row.title,
    encryptedContent: row.encryptedContent,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    isPinned: row.isPinned,
  );

  NotesTableCompanion _modelToCompanion(NoteModel note) => NotesTableCompanion(
    id: Value(note.id),
    title: Value(note.title),
    encryptedContent: Value(note.encryptedContent),
    createdAt: Value(note.createdAt.millisecondsSinceEpoch),
    updatedAt: Value(note.updatedAt.millisecondsSinceEpoch),
    isPinned: Value(note.isPinned),
  );
}
