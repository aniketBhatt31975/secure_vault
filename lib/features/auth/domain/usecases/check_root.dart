import '../repositories/auth_repository.dart';

class CheckRoot {
  final AuthRepository repository;
  CheckRoot(this.repository);

  Future<bool> call() => repository.isDeviceRooted();
}
