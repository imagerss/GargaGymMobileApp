import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_models.dart';

class SessionStore {
  SessionStore({
    FlutterSecureStorage? secureStorage,
    SharedPreferencesAsync? preferences,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _preferences = preferences ?? SharedPreferencesAsync();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _lastUserIdKey = 'last_auth_user_id';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferencesAsync _preferences;

  Future<void> saveSession(AuthSession session) async {
    await _secureStorage.write(key: _tokenKey, value: session.token);
    await _preferences.setString(_userKey, jsonEncode(session.user.toJson()));
    await _preferences.setInt(_lastUserIdKey, session.user.id);
  }

  Future<String?> readToken() => _secureStorage.read(key: _tokenKey);

  Future<AuthUser?> readUser() async {
    final raw = await _preferences.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<int?> readLastUserId() => _preferences.getInt(_lastUserIdKey);

  Future<void> clearSession() async {
    await _secureStorage.delete(key: _tokenKey);
    await _preferences.remove(_userKey);
  }
}
