import 'package:hive_flutter/hive_flutter.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../models/note_model.dart';
import 'db_interface.dart';

class HiveDatasource implements DbInterface {
  late Box<Map> _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox<Map>(AppConstants.hiveNotesBox);
  }

  @override
  Future<List<NoteModel>> getNotes() async {
    try {
      return _box.values
          .map((e) => NoteModel.fromMap(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      throw StorageException('HiveGet failed: $e');
    }
  }

  @override
  Future<NoteModel?> getNoteById(String id) async {
    try {
      final raw = _box.get(id);
      if (raw == null) return null;
      return NoteModel.fromMap(Map<String, dynamic>.from(raw));
    } catch (e) {
      throw StorageException('HiveGetById failed: $e');
    }
  }

  @override
  Future<void> insertNote(NoteModel note) async {
    try {
      await _box.put(note.id, note.toMap());
    } catch (e) {
      throw StorageException('HiveInsert failed: $e');
    }
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    try {
      await _box.put(note.id, note.toMap());
    } catch (e) {
      throw StorageException('HiveUpdate failed: $e');
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StorageException('HiveDelete failed: $e');
    }
  }

  @override
  Future<List<NoteModel>> searchNotes(String query) async {
    try {
      final lower = query.toLowerCase();
      return _box.values
          .map((e) => NoteModel.fromMap(Map<String, dynamic>.from(e)))
          .where((n) => n.title.toLowerCase().contains(lower))
          .toList();
    } catch (e) {
      throw StorageException('HiveSearch failed: $e');
    }
  }

  @override
  Future<void> close() async => _box.close();
}
