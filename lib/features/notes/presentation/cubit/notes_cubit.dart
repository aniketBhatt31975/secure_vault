import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/result.dart';
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
    emit(NotesLoading());
    switch (await _getNotes.call()) {
      case Ok(:final data):
        emit(NotesLoaded(data));
      case Err(:final failure):
        emit(NotesError(failure.message));
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
    switch (await _createNote.call(note)) {
      case Ok():
        await loadNotes();
      case Err(:final failure):
        emit(NotesError(failure.message));
    }
  }

  Future<void> updateNote(Note note) async {
    switch (await _updateNote.call(note.copyWith(updatedAt: DateTime.now()))) {
      case Ok():
        await loadNotes();
      case Err(:final failure):
        emit(NotesError(failure.message));
    }
  }

  Future<void> deleteNote(String id) async {
    switch (await _deleteNote.call(id)) {
      case Ok():
        await loadNotes();
      case Err(:final failure):
        emit(NotesError(failure.message));
    }
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      await loadNotes();
      return;
    }
    switch (await _searchNotes.call(query)) {
      case Ok(:final data):
        emit(NotesLoaded(data));
      case Err(:final failure):
        emit(NotesError(failure.message));
    }
  }

  Future<void> togglePin(Note note) async {
    switch (await _updateNote.call(note.copyWith(isPinned: !note.isPinned))) {
      case Ok():
        await loadNotes();
      case Err(:final failure):
        emit(NotesError(failure.message));
    }
  }
}
