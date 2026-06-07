import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/authenticate_biometric.dart';
import '../../../../core/router/route_guards.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthenticateBiometric _authenticateBiometric;

  AuthCubit({required AuthenticateBiometric authenticateBiometric})
    : _authenticateBiometric = authenticateBiometric,

      super(AuthInitial());

  Future<void> checkAndAuthenticate() async {
    emit(AuthLoading());
    try {
      final success = await _authenticateBiometric.call();
      if (success) {
        RouteGuards.markAuthenticated();
        emit(AuthAuthenticated());
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void lock() {
    RouteGuards.markLocked();
    emit(AuthUnauthenticated());
  }
}
