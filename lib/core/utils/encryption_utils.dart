import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import '../constants/encryption_constants.dart';
import '../errors/exceptions.dart';

class EncryptionUtils {
  static String encrypt(String plainText, String base64Key) {
    try {
      final keyBytes = base64Decode(base64Key);
      final key = Key(Uint8List.fromList(keyBytes));
      final iv = IV.fromSecureRandom(EncryptionConstants.ivLength);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      // Prefix IV to ciphertext so decrypt can recover it
      final combined = iv.bytes + encrypted.bytes;
      return base64Encode(combined);
    } catch (e) {
      throw EncryptionException('Encryption failed: $e');
    }
  }

  static String decrypt(String cipherText, String base64Key) {
    try {
      final keyBytes = base64Decode(base64Key);
      final combined = base64Decode(cipherText);
      // First 16 bytes are the IV
      final ivBytes = Uint8List.fromList(combined.sublist(0, EncryptionConstants.ivLength));
      final encryptedBytes = Uint8List.fromList(combined.sublist(EncryptionConstants.ivLength));
      final key = Key(Uint8List.fromList(keyBytes));
      final iv = IV(ivBytes);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      return encrypter.decrypt(Encrypted(encryptedBytes), iv: iv);
    } catch (e) {
      throw EncryptionException('Decryption failed: $e');
    }
  }
}
