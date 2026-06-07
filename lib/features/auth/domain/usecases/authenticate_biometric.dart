import '../repositories/auth_repository.dart';

class AuthenticateBiometric {
  final AuthRepository repository;
  AuthenticateBiometric(this.repository);

  Future<bool> call() => repository.authenticateBiometric();
}
