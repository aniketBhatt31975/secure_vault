import 'package:flutter/services.dart';
import '../../../../core/errors/exceptions.dart';

class KeystoreChannel {
  static const _channel = MethodChannel('com.example.secure_vault/keystore');

  Future<String> getOrCreateKey() async {
    try {
      final key = await _channel.invokeMethod<String>('getOrCreateKey');
      if (key == null) throw const KeystoreException('Key returned null');
      return key;
    } on PlatformException catch (e) {
      throw KeystoreException('getOrCreateKey failed: ${e.message}');
    }
  }

  Future<void> deleteKey() async {
    try {
      await _channel.invokeMethod<void>('deleteKey');
    } on PlatformException catch (e) {
      throw KeystoreException('deleteKey failed: ${e.message}');
    }
  }
}
