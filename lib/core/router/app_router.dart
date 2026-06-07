import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/lock_screen.dart';
import '../../features/notes/presentation/screens/notes_list_screen.dart';
import '../../features/notes/presentation/screens/note_detail_screen.dart';
import '../../features/notes/presentation/screens/note_editor_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import 'route_guards.dart';
import 'route_names.dart';

final appRouter = GoRouter(
  initialLocation: RouteNames.lock,
  redirect: (context, state) => RouteGuards.authRedirect(state),
  routes: [
    GoRoute(
      path: RouteNames.lock,
      builder: (context, state) => const LockScreen(),
    ),
    GoRoute(
      path: RouteNames.notes,
      builder: (context, state) => const NotesListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const NoteEditorScreen(),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) => NoteDetailScreen(id: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => NoteEditorScreen(id: state.pathParameters['id']),
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
