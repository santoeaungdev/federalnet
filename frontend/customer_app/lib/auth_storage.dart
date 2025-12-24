import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _key = 'jwt';
  static const _prefsKey = 'jwt_fallback';
  static const _storage = FlutterSecureStorage();

  static Future<void> writeToken(String token) async {
    try {
      await _storage.write(key: _key, value: token);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, token);
    }
  }

  static Future<String?> readToken() async {
    try {
      final v = await _storage.read(key: _key);
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_prefsKey);
    return (v != null && v.isNotEmpty) ? v : null;
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
