import '../../../../core/utils/biometric_utils.dart';

class BiometricDatasource {
  Future<bool> isAvailable() => BiometricUtils.isAvailable();
  Future<bool> authenticate() => BiometricUtils.authenticate();
}
