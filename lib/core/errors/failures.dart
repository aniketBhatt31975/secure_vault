import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  @override
  List<Object?> get props => [message];
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class EncryptionFailure extends Failure {
  const EncryptionFailure(super.message);
}

class BiometricFailure extends Failure {
  const BiometricFailure(super.message);
}

class RootedDeviceFailure extends Failure {
  const RootedDeviceFailure() : super('Device is rooted or jailbroken');
}

class KeystoreFailure extends Failure {
  const KeystoreFailure(super.message);
}
