import '../../models/note_model.dart';

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
