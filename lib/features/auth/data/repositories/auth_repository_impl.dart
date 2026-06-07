import '../../domain/repositories/auth_repository.dart';
import '../datasources/biometric_datasource.dart';
import '../datasources/keystore_channel.dart';
import '../datasources/root_detection_channel.dart';

class AuthRepositoryImpl implements AuthRepository {
  final BiometricDatasource biometricDatasource;
  final KeystoreChannel keystoreChannel;
  final RootDetectionChannel rootDetectionChannel;

  AuthRepositoryImpl({
    required this.biometricDatasource,
    required this.keystoreChannel,
    required this.rootDetectionChannel,
  });

  @override
  Future<bool> authenticateBiometric() => biometricDatasource.authenticate();

  @override
  Future<bool> isBiometricAvailable() => biometricDatasource.isAvailable();

  @override
  Future<bool> isDeviceRooted() => rootDetectionChannel.isRooted();

  @override
  Future<String> getEncryptionKey() => keystoreChannel.getOrCreateKey();
}
