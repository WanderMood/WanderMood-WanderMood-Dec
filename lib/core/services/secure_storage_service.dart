import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for sensitive data stored in secure storage (Keychain/Keystore).
class SecureStorageKeys {
  static const hasSeenOnboarding = 'has_seen_onboarding';
  static const hasCompletedPreferences = 'hasCompletedPreferences';
  static const rememberMe = 'remember_me';
  static const lastAuthTimestamp = 'last_auth_timestamp';
  static String profileCache(String userId) => 'profile_cache_$userId';
}

/// Stores and retrieves sensitive preferences in platform secure storage.
/// Migrates from SharedPreferences on first read so existing users keep their state.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage, SharedPreferences? prefs})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        ),
        _prefs = prefs;

  final FlutterSecureStorage _storage;
  final SharedPreferences? _prefs;

  static SharedPreferences? _sharedPrefs;
  static set sharedPrefs(SharedPreferences? value) => _sharedPrefs = value;

  SharedPreferences? get _migrateFrom => _prefs ?? _sharedPrefs;

  Future<bool> getHasSeenOnboarding() async =>
      await _getBool(SecureStorageKeys.hasSeenOnboarding) ?? false;

  Future<void> setHasSeenOnboarding(bool value) async =>
      await _setBool(SecureStorageKeys.hasSeenOnboarding, value);

  Future<bool> getHasCompletedPreferences() async =>
      await _getBool(SecureStorageKeys.hasCompletedPreferences) ?? false;

  Future<void> setHasCompletedPreferences(bool value) async =>
      await _setBool(SecureStorageKeys.hasCompletedPreferences, value);

  Future<bool> getRememberMe() async =>
      await _getBool(SecureStorageKeys.rememberMe) ?? false;

  Future<void> setRememberMe(bool value) async =>
      await _setBool(SecureStorageKeys.rememberMe, value);

  Future<int?> getLastAuthTimestamp() async =>
      await _getInt(SecureStorageKeys.lastAuthTimestamp);

  Future<void> setLastAuthTimestamp(int value) async =>
      await _setInt(SecureStorageKeys.lastAuthTimestamp, value);

  Future<void> clearAuthSensitive() async {
    await _storage.delete(key: SecureStorageKeys.hasSeenOnboarding);
    await _storage.delete(key: SecureStorageKeys.hasCompletedPreferences);
    await _storage.delete(key: SecureStorageKeys.rememberMe);
    await _storage.delete(key: SecureStorageKeys.lastAuthTimestamp);
  }

  Future<bool?> _getBool(String key) async {
    final raw = await _storage.read(key: key);
    if (raw != null) return raw == 'true';
    final prefs = _migrateFrom;
    if (prefs != null) {
      final value = prefs.getBool(key);
      if (value != null) {
        await _setBool(key, value);
        await prefs.remove(key);
        return value;
      }
    }
    return null;
  }

  Future<void> _setBool(String key, bool value) async =>
      await _storage.write(key: key, value: value.toString());

  Future<int?> _getInt(String key) async {
    final raw = await _storage.read(key: key);
    if (raw != null) return int.tryParse(raw);
    final prefs = _migrateFrom;
    if (prefs != null) {
      final value = prefs.getInt(key);
      if (value != null) {
        await _setInt(key, value);
        await prefs.remove(key);
        return value;
      }
    }
    return null;
  }

  Future<void> _setInt(String key, int value) async =>
      await _storage.write(key: key, value: value.toString());
}
