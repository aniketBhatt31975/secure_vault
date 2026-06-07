import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/notes_cubit.dart';
import '../cubit/notes_state.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? id;

  const NoteEditorScreen({super.key, this.id});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _populated = false;
  bool _saving = false;

  bool get _isEditing => widget.id != null;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _populateFromState(NotesLoaded state) {
    if (_populated) return;
    final note = state.notes.firstWhere(
      (n) => n.id == widget.id,
      orElse: () => throw StateError('Note not found'),
    );
    _titleController.text = note.title;
    _contentController.text = note.encryptedContent;
    _populated = true;
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final cubit = context.read<NotesCubit>();
      if (_isEditing) {
        final state = cubit.state as NotesLoaded;
        final existing = state.notes.firstWhere((n) => n.id == widget.id!);
        await cubit.updateNote(
          existing.copyWith(title: title, encryptedContent: content),
        );
      } else {
        await cubit.createNote(title: title, content: content);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotesCubit, NotesState>(
      builder: (context, state) {
        if (_isEditing && state is NotesLoaded && !_populated) {
          _populateFromState(state);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit Note' : 'New Note'),
            actions: [
              _saving
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.check),
                      tooltip: 'Save',
                      onPressed: _save,
                    ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  style: Theme.of(context).textTheme.titleLarge,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.next,
                  maxLines: 1,
                ),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText: 'Write your note…',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
