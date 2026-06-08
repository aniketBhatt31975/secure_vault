import '../../../../core/utils/result.dart';
import '../repositories/note_repository.dart';

class DeleteNote {
  final NoteRepository repository;
  DeleteNote(this.repository);

  Future<Result<void>> call(String id) => repository.deleteNote(id);
}
