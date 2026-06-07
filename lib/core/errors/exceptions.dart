class StorageException implements Exception {
  final String message;
  const StorageException(this.message);
  @override
  String toString() => 'StorageException: $message';
}

class EncryptionException implements Exception {
  final String message;
  const EncryptionException(this.message);
  @override
  String toString() => 'EncryptionException: $message';
}

class BiometricException implements Exception {
  final String message;
  const BiometricException(this.message);
  @override
  String toString() => 'BiometricException: $message';
}

class RootedException implements Exception {
  const RootedException();
  @override
  String toString() => 'RootedException: Device is rooted or jailbroken';
}

class KeystoreException implements Exception {
  final String message;
  const KeystoreException(this.message);
  @override
  String toString() => 'KeystoreException: $message';
}
