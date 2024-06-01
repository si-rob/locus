import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' as foundation;

class EncryptionService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _keyStorageKey = dotenv.env['KEY_STORAGE_KEY']!;
  final String _ivStorageKey = dotenv.env['IV_STORAGE_KEY']!;

  Future<void> _initializeKeys() async {
    String? keyString = await _secureStorage.read(key: _keyStorageKey);
    String? ivString = await _secureStorage.read(key: _ivStorageKey);

    if (keyString == null || ivString == null) {
      if (foundation.kDebugMode) {
        // ignore: avoid_print
        print("Keys are missing, likely due to app reinstallation. Regenerating keys...");
      }
      final key = encrypt.Key.fromSecureRandom(32); // Generate a 256-bit key
      final iv = encrypt.IV.fromSecureRandom(16);   // Generate a 128-bit IV
      await _secureStorage.write(key: _keyStorageKey, value: key.base64);
      await _secureStorage.write(key: _ivStorageKey, value: iv.base64);
    }
  }

  Future<encrypt.Encrypter> _getEncrypter() async {
    await _initializeKeys();
    final keyString = await _secureStorage.read(key: _keyStorageKey);
    final key = encrypt.Key.fromBase64(keyString!);
    return encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc)); // Use CBC mode for AES
  }

  Future<String> encryptText(String text) async {
    final encrypter = await _getEncrypter();
    final ivString = await _secureStorage.read(key: _ivStorageKey);
    final iv = encrypt.IV.fromBase64(ivString!); // Use the IV
    final encrypted = encrypter.encrypt(text, iv: iv);
    return encrypted.base64;
  }

  Future<String> decryptText(String encryptedText) async {
    final encrypter = await _getEncrypter();
    final ivString = await _secureStorage.read(key: _ivStorageKey);
    final iv = encrypt.IV.fromBase64(ivString!); // Use the IV
    final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return decrypted;
  }
}
