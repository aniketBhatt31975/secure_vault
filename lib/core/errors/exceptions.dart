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
