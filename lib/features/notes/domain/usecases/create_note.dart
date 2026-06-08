import '../../../../core/utils/result.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class CreateNote {
  final NoteRepository repository;
  CreateNote(this.repository);

  Future<Result<void>> call(Note note) => repository.createNote(note);
}
