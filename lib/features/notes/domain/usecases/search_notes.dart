import '../../../../core/utils/result.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class SearchNotes {
  final NoteRepository repository;
  SearchNotes(this.repository);

  Future<Result<List<Note>>> call(String query) => repository.searchNotes(query);
}
