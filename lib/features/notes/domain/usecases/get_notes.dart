import '../../../../core/utils/result.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetNotes {
  final NoteRepository repository;
  GetNotes(this.repository);

  Future<Result<List<Note>>> call() => repository.getNotes();
}
