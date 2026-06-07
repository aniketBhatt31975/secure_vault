import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:secure_vault/core/di/injection_container.dart';
import 'package:secure_vault/features/notes/presentation/cubit/notes_cubit.dart';
import '../../features/notes/presentation/screens/notes_list_screen.dart';
import '../../features/notes/presentation/screens/note_detail_screen.dart';
import '../../features/notes/presentation/screens/note_editor_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import 'route_names.dart';

final appRouter = GoRouter(
  initialLocation: RouteNames.notes,
  routes: [
    GoRoute(
      path: RouteNames.notes,
      builder:
          (context, state) => BlocProvider(
            create: (context) {
              return NotesCubit(
                getNotes: sl.get(),
                createNote: sl.get(),
                updateNote: sl.get(),
                deleteNote: sl.get(),
                searchNotes: sl.get(),
              );
              // return const NotesListScreen();
            },
            child: NotesListScreen(),
          ),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const NoteEditorScreen(),
        ),
        GoRoute(
          path: ':id',
          builder:
              (context, state) =>
                  NoteDetailScreen(id: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'edit',
              builder:
                  (context, state) =>
                      NoteEditorScreen(id: state.pathParameters['id']),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: RouteNames.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
