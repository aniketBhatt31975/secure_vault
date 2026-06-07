import 'package:local_auth/local_auth.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

class BiometricUtils {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    return canCheck && isSupported;
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: AppConstants.biometricReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      throw BiometricException('Authentication failed: $e');
    }
  }
}
