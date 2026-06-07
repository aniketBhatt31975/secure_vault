import '../repositories/note_repository.dart';

class DeleteNote {
  final NoteRepository repository;
  DeleteNote(this.repository);

  Future<void> call(String id) => repository.deleteNote(id);
}
