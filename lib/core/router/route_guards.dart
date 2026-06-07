import 'package:go_router/go_router.dart';
import 'route_names.dart';

class RouteGuards {
  static bool _authenticated = false;

  static void markAuthenticated() => _authenticated = true;
  static void markLocked() => _authenticated = false;

  static String? authRedirect(GoRouterState state) {
    print("state ${state.name}");
    final isLockScreen = state.matchedLocation == RouteNames.lock;
    if (!_authenticated && !isLockScreen) return RouteNames.lock;
    if (_authenticated && isLockScreen) return RouteNames.notes;
    return null;
  }
}
