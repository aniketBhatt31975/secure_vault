import 'package:flutter/services.dart';
import '../../../../core/errors/exceptions.dart';

class RootDetectionChannel {
  static const _channel = MethodChannel('com.example.secure_vault/root_detection');

  Future<bool> isRooted() async {
    try {
      final result = await _channel.invokeMethod<bool>('isRooted');
      return result ?? false;
    } on PlatformException catch (e) {
      throw KeystoreException('isRooted check failed: ${e.message}');
    }
  }
}
