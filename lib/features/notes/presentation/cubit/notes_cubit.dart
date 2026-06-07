import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/note.dart';
import '../../domain/usecases/create_note.dart';
import '../../domain/usecases/delete_note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/search_notes.dart';
import '../../domain/usecases/update_note.dart';
import 'notes_state.dart';

class NotesCubit extends Cubit<NotesState> {
  final GetNotes _getNotes;
  final CreateNote _createNote;
  final UpdateNote _updateNote;
  final DeleteNote _deleteNote;
  final SearchNotes _searchNotes;

  NotesCubit({
    required GetNotes getNotes,
    required CreateNote createNote,
    required UpdateNote updateNote,
    required DeleteNote deleteNote,
    required SearchNotes searchNotes,
  }) : _getNotes = getNotes,
       _createNote = createNote,
       _updateNote = updateNote,
       _deleteNote = deleteNote,
       _searchNotes = searchNotes,
       super(NotesInitial());

  Future<void> loadNotes() async {
    try {
      emit(NotesLoading());
      final notes = await _getNotes.call();
      emit(NotesLoaded(notes));
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> createNote({
    required String title,
    required String content,
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: const Uuid().v4(),
      title: title,
      encryptedContent: content,
      createdAt: now,
      updatedAt: now,
    );
    await _createNote.call(note);
    await loadNotes();
  }

  Future<void> updateNote(Note note) async {
    await _updateNote.call(note.copyWith(updatedAt: DateTime.now()));
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _deleteNote.call(id);
    await loadNotes();
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      await loadNotes();
      return;
    }
    try {
      final notes = await _searchNotes.call(query);
      emit(NotesLoaded(notes));
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> togglePin(Note note) async {
    await _updateNote.call(note.copyWith(isPinned: !note.isPinned));
    await loadNotes();
  }
}
