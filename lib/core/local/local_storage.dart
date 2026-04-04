import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorage {
  Future<void> init();

  Future<String?> get accessToken;
  Future<String?> get refreshToken;
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clearTokens();

  Future<bool> get isLoggedIn;

  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
  Future<void> setBool(String key, {required bool value});
  Future<bool?> getBool(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

class LocalStorageImpl implements LocalStorage {
  static const _ACCESS_TOKEN_KEY = 'access_token';
  static const _REFRESH_TOKEN_KEY = 'refresh_token';

  late final FlutterSecureStorage _secure;
  late final SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _secure = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<String?> get accessToken => _secure.read(key: _ACCESS_TOKEN_KEY);

  @override
  Future<String?> get refreshToken => _secure.read(key: _REFRESH_TOKEN_KEY);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _secure.write(key: _ACCESS_TOKEN_KEY, value: accessToken),
      _secure.write(key: _REFRESH_TOKEN_KEY, value: refreshToken),
    ]);
  }

  @override
  Future<void> clearTokens() async {
    await Future.wait([
      _secure.delete(key: _ACCESS_TOKEN_KEY),
      _secure.delete(key: _REFRESH_TOKEN_KEY),
    ]);
  }

  @override
  Future<bool> get isLoggedIn async {
    final token = await accessToken;
    return token != null;
  }

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  @override
  Future<void> setBool(String key, {required bool value}) async {
    await _prefs.setBool(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    return _prefs.getBool(key);
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _prefs.clear(),
      _secure.deleteAll(),
    ]);
  }
}
