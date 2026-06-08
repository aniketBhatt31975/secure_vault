import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/local/db_interface.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  final DbInterface db;

  NoteRepositoryImpl({required this.db});

  @override
  Future<Result<List<Note>>> getNotes() async {
    try {
      final models = await db.getNotes();
      return Ok(models.map(_toEntity).toList());
    } on StorageException catch (e) {
      return Err(StorageFailure(e.message));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Note>> getNoteById(String id) async {
    try {
      final model = await db.getNoteById(id);
      if (model == null) return Err(NotFoundFailure('Note not found: $id'));
      return Ok(_toEntity(model));
    } on StorageException catch (e) {
      return Err(StorageFailure(e.message));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> createNote(Note note) async {
    try {
      await db.insertNote(NoteModel.fromEntity(note));
      return Ok(null);
    } on StorageException catch (e) {
      return Err(StorageFailure(e.message));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateNote(Note note) async {
    try {
      await db.updateNote(NoteModel.fromEntity(note));
      return Ok(null);
    } on StorageException catch (e) {
      return Err(StorageFailure(e.message));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteNote(String id) async {
    try {
      await db.deleteNote(id);
      return Ok(null);
    } on StorageException catch (e) {
      return Err(StorageFailure(e.message));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<Note>>> searchNotes(String query) async {
    final result = await getNotes();
    if (result is Err<List<Note>>) return result;
    final data = (result as Ok<List<Note>>).data;
    return Ok(
      data
          .where((n) => n.title.toLowerCase().contains(query.toLowerCase()))
          .toList(),
    );
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
