import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _keyStorageKey = 'encryption_key';
  final String _ivStorageKey = 'encryption_iv';

  Future<void> _initializeKeys() async {
    String? keyString = await _secureStorage.read(key: _keyStorageKey);
    String? ivString = await _secureStorage.read(key: _ivStorageKey);

    if (keyString == null || ivString == null) {
      final key = Key.fromSecureRandom(32);
      final iv = IV.fromSecureRandom(16);
      await _secureStorage.write(key: _keyStorageKey, value: key.base64);
      await _secureStorage.write(key: _ivStorageKey, value: iv.base64);
    }
  }

  Future<Encrypter> _getEncrypter() async {
    await _initializeKeys();
    final keyString = await _secureStorage.read(key: _keyStorageKey);
    final key = Key.fromBase64(keyString!);
    return Encrypter(AES(key, mode: AESMode.cbc));
  }

  Future<String> encryptText(String text) async {
    final encrypter = await _getEncrypter();
    final ivString = await _secureStorage.read(key: _ivStorageKey);
    final iv = IV.fromBase64(ivString!); // Ensure iv is used
    final encrypted = encrypter.encrypt(text, iv: iv);
    return encrypted.base64;
  }

  Future<String> decryptText(String encryptedText) async {
    final encrypter = await _getEncrypter();
    final ivString = await _secureStorage.read(key: _ivStorageKey);
    final iv = IV.fromBase64(ivString!); // Ensure iv is used
    final encrypted = Encrypted.fromBase64(encryptedText);
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return decrypted;
  }
}
