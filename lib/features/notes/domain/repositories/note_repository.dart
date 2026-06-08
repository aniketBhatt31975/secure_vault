import '../../../../core/utils/result.dart';
import '../entities/note.dart';

abstract class NoteRepository {
  Future<Result<List<Note>>> getNotes();
  Future<Result<Note>> getNoteById(String id);
  Future<Result<void>> createNote(Note note);
  Future<Result<void>> updateNote(Note note);
  Future<Result<void>> deleteNote(String id);
  Future<Result<List<Note>>> searchNotes(String query);
}
