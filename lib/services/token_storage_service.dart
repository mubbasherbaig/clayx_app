import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorageService {
  static const _tokenKey = 'auth_token';

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  Future<String?> getToken() async {
    try {
      // Try secure storage first
      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null) {
        print('[TOKEN] Read from secure storage');
        return token;
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final spToken = prefs.getString(_tokenKey);
      if (spToken != null) {
        print('[TOKEN] Read from SharedPreferences');
      }
      return spToken;
    } catch (e) {
      print('[TOKEN] Error reading from secure storage: $e');

      // Fallback to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_tokenKey);
      } catch (e2) {
        print('[TOKEN] Error reading from SharedPreferences: $e2');
        return null;
      }
    }
  }

  Future<void> saveToken(String token) async {
    bool savedToSecure = false;

    // Try secure storage first
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      print('[TOKEN] ✅ Saved to secure storage');
      savedToSecure = true;
    } catch (e) {
      print('[TOKEN] ⚠️ Secure storage failed: $e');
    }

    // ALWAYS save to SharedPreferences as backup
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      print('[TOKEN] ✅ Saved to SharedPreferences');
    } catch (e2) {
      print('[TOKEN] ⚠️ SharedPreferences failed: $e2');
      if (!savedToSecure) {
        throw Exception('All storage methods failed');
      }
    }
  }

  Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (e) {
      print('[TOKEN] Error deleting from secure storage: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      print('[TOKEN] Error deleting from SharedPreferences: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      print('[TOKEN] Error clearing secure storage: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('[TOKEN] Error clearing SharedPreferences: $e');
    }
  }
}