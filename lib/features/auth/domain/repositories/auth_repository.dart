abstract class AuthRepository {
  Future<bool> authenticateBiometric();
  Future<bool> isDeviceRooted();
  Future<String> getEncryptionKey();
  Future<bool> isBiometricAvailable();
}
