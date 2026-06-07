import '../repositories/auth_repository.dart';

class GetEncryptionKey {
  final AuthRepository repository;
  GetEncryptionKey(this.repository);

  Future<String> call() => repository.getEncryptionKey();
}
