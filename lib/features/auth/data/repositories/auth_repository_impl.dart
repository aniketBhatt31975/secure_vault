import '../../domain/repositories/auth_repository.dart';
import '../datasources/biometric_datasource.dart';
import '../datasources/keystore_channel.dart';

class AuthRepositoryImpl implements AuthRepository {
  final BiometricDatasource biometricDatasource;
  final KeystoreChannel keystoreChannel;

  AuthRepositoryImpl({
    required this.biometricDatasource,
    required this.keystoreChannel,
  });

  @override
  Future<bool> authenticateBiometric() => biometricDatasource.authenticate();

  @override
  Future<bool> isBiometricAvailable() => biometricDatasource.isAvailable();

  @override
  Future<String> getEncryptionKey() => keystoreChannel.getOrCreateKey();
}
