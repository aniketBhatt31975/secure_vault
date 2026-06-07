import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/notes_cubit.dart';
import '../cubit/notes_state.dart';

class NoteDetailScreen extends StatelessWidget {
  final String id;

  const NoteDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotesCubit, NotesState>(
      builder: (context, state) {
        if (state is! NotesLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final noteOrNull = state.notes.where((n) => n.id == id).firstOrNull;

        if (noteOrNull == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Note not found')),
          );
        }

        final note = noteOrNull;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              note.title,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: note.isPinned
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: () =>
                    context.read<NotesCubit>().togglePin(note),
                tooltip: note.isPinned ? 'Unpin' : 'Pin',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Theme.of(context).colorScheme.error,
                onPressed: () => _confirmDelete(context),
                tooltip: 'Delete',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(note.updatedAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  note.encryptedContent,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/notes/$id/edit'),
            child: const Icon(Icons.edit_outlined),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NotesCubit>().deleteNote(id);
              context.pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return 'Last edited ${dt.day}/${dt.month}/${dt.year} at '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
