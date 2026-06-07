abstract class AuthRepository {
  Future<bool> authenticateBiometric();
  Future<String> getEncryptionKey();
  Future<bool> isBiometricAvailable();
}
