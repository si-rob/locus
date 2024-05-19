// lib/encryption_service.dart

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EncryptionService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _keyStorageKey = dotenv.env['KEY_STORAGE_KEY']!;
  final String _ivStorageKey = dotenv.env['IV_STORAGE_KEY']!;

  Future<void> _initializeKeys() async {
    String? keyString = await _secureStorage.read(key: _keyStorageKey);
    String? ivString = await _secureStorage.read(key: _ivStorageKey);

    if (keyString == null || ivString == null) {
      final key = Key.fromSecureRandom(32); // Generate a 256-bit key
      final iv = IV.fromSecureRandom(16);   // Generate a 128-bit IV
      await _secureStorage.write(key: _keyStorageKey, value: key.base64);
      await _secureStorage.write(key: _ivStorageKey, value: iv.base64);
    }
  }

  Future<Encrypter> _getEncrypter() async {
    await _initializeKeys();
    final keyString = await _secureStorage.read(key: _keyStorageKey);
    final key = Key.fromBase64(keyString!);
    return Encrypter(AES(key, mode: AESMode.cbc)); // Use CBC mode for AES
  }

  Future<String> encryptText(String text) async {
    final encrypter = await _getEncrypter();
    final ivString = await _secureStorage.read(key: _ivStorageKey);
    final iv = IV.fromBase64(ivString!); // Use the IV
    final encrypted = encrypter.encrypt(text, iv: iv);
    return encrypted.base64;
  }

  Future<String> decryptText(String encryptedText) async {
    final encrypter = await _getEncrypter();
    final ivString = await _secureStorage.read(key: _ivStorageKey);
    final iv = IV.fromBase64(ivString!); // Use the IV
    final encrypted = Encrypted.fromBase64(encryptedText);
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return decrypted;
  }
}
