import '../../../../core/utils/result.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class UpdateNote {
  final NoteRepository repository;
  UpdateNote(this.repository);

  Future<Result<void>> call(Note note) => repository.updateNote(note);
}
