import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' as foundation; // Import foundation for kDebugMode

class EncryptionService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _keyStorageKey = dotenv.env['KEY_STORAGE_KEY']!;
  final String _ivStorageKey = dotenv.env['IV_STORAGE_KEY']!;

  Future<void> _initializeKeys() async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    String? keyString = await _secureStorage.read(key: _keyStorageKey);
    String? ivString = await _secureStorage.read(key: _ivStorageKey);

    if (keyString == null || ivString == null) {
      final doc = await _firestore.collection('encryptionKeys').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        keyString = data?['key'];
        ivString = data?['iv'];

        await _secureStorage.write(key: _keyStorageKey, value: keyString);
        await _secureStorage.write(key: _ivStorageKey, value: ivString);
      } else {
        final key = encrypt.Key.fromSecureRandom(32); // Generate a 256-bit key
        final iv = encrypt.IV.fromSecureRandom(16);   // Generate a 128-bit IV
        keyString = key.base64;
        ivString = iv.base64;

        await _secureStorage.write(key: _keyStorageKey, value: keyString);
        await _secureStorage.write(key: _ivStorageKey, value: ivString);

        await _firestore.collection('encryptionKeys').doc(user.uid).set({
          'key': keyString,
          'iv': ivString,
        });
      }
    }

    if (foundation.kDebugMode) {
      print("Encryption keys initialized");
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
