import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../cubit/notes_cubit.dart';
import '../cubit/notes_state.dart';
import '../widgets/note_card.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final _searchController = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    context.read<NotesCubit>().loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _searching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search notes…',
                    border: InputBorder.none,
                  ),
                  onChanged: (q) => context.read<NotesCubit>().search(q),
                )
                : const Text('Secure Vault'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _searching = !_searching);
              if (!_searching) {
                _searchController.clear();
                context.read<NotesCubit>().loadNotes();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RouteNames.settings),
          ),
        ],
      ),
      body: BlocBuilder<NotesCubit, NotesState>(
        builder: (context, state) {
          if (state is NotesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<NotesCubit>().loadNotes(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is NotesLoaded) {
            if (state.notes.isEmpty) {
              return const Center(
                child: Text('No notes yet. Tap + to create one.'),
              );
            }

            final pinned = state.notes.where((n) => n.isPinned).toList();
            final unpinned = state.notes.where((n) => !n.isPinned).toList();

            return ListView(
              children: [
                if (pinned.isNotEmpty) ...[
                  _SectionHeader('Pinned'),
                  ...pinned.map(
                    (note) => NoteCard(
                      key: ValueKey(note.id),
                      note: note,
                      onTap: () => context.push('/notes/${note.id}'),
                      onDelete: () => _confirmDelete(context, note.id),
                      onTogglePin:
                          () => context.read<NotesCubit>().togglePin(note),
                    ),
                  ),
                ],
                if (unpinned.isNotEmpty) ...[
                  if (pinned.isNotEmpty) _SectionHeader('Others'),
                  ...unpinned.map(
                    (note) => NoteCard(
                      key: ValueKey(note.id),
                      note: note,
                      onTap: () => context.push('/notes/${note.id}'),
                      onDelete: () => _confirmDelete(context, note.id),
                      onTogglePin:
                          () => context.read<NotesCubit>().togglePin(note),
                    ),
                  ),
                ],
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.newNote),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete note?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<NotesCubit>().deleteNote(id);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
