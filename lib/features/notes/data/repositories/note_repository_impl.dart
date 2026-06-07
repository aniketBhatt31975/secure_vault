import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../../../core/errors/exceptions.dart';
import '../datasources/local/db_interface.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  final DbInterface db;

  NoteRepositoryImpl({required this.db});

  @override
  Future<List<Note>> getNotes() async {
    final models = await db.getNotes();
    return models.map((e) => _toEntity(e)).toList();
  }

  @override
  Future<Note> getNoteById(String id) async {
    final model = await db.getNoteById(id);
    if (model == null) throw StorageException('Note not found: $id');
    return _toEntity(model);
  }

  @override
  Future<void> createNote(Note note) async {
    await db.insertNote(NoteModel.fromEntity(note));
  }

  @override
  Future<void> updateNote(Note note) async {
    await db.updateNote(NoteModel.fromEntity(note));
  }

  @override
  Future<void> deleteNote(String id) => db.deleteNote(id);

  @override
  Future<List<Note>> searchNotes(String query) async {
    final all = await getNotes();
    final lower = query.toLowerCase();
    return all.where((n) => n.title.toLowerCase().contains(lower)).toList();
  }

  Note _toEntity(NoteModel model) => Note(
    id: model.id,
    title: model.title,
    encryptedContent: model.encryptedContent,
    createdAt: model.createdAt,
    updatedAt: model.updatedAt,
    isPinned: model.isPinned,
  );
}
