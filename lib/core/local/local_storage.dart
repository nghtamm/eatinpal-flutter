import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorage {
  Future<void> init();

  Future<String?> get accessToken;

  Future<String?> get refreshToken;

  Future<String?> get verificationToken;

  Future<String?> get user;

  Future<void> saveCredentialsToken({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> saveVerificationToken(String token);

  Future<void> saveUser(String userJSON);

  Future<void> clearCredentialsToken();

  Future<void> clearVerificationToken();

  Future<void> clearUser();

  Future<bool> get signed;

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
  static const _VERIFICATION_TOKEN_KEY = 'verification_token';
  static const _USER_KEY = 'user';

  late final FlutterSecureStorage _secure;
  late final SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _secure = const FlutterSecureStorage(aOptions: AndroidOptions());
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<String?> get accessToken => _secure.read(key: _ACCESS_TOKEN_KEY);

  @override
  Future<String?> get refreshToken => _secure.read(key: _REFRESH_TOKEN_KEY);

  @override
  Future<String?> get verificationToken =>
      _secure.read(key: _VERIFICATION_TOKEN_KEY);

  @override
  Future<String?> get user async => _prefs.getString(_USER_KEY);

  @override
  Future<void> saveCredentialsToken({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _secure.write(key: _ACCESS_TOKEN_KEY, value: accessToken),
      _secure.write(key: _REFRESH_TOKEN_KEY, value: refreshToken),
    ]);
  }

  @override
  Future<void> saveVerificationToken(String token) async {
    await _secure.write(key: _VERIFICATION_TOKEN_KEY, value: token);
  }

  @override
  Future<void> saveUser(String userJSON) async {
    await _prefs.setString(_USER_KEY, userJSON);
  }

  @override
  Future<void> clearCredentialsToken() async {
    await Future.wait([
      _secure.delete(key: _ACCESS_TOKEN_KEY),
      _secure.delete(key: _REFRESH_TOKEN_KEY),
    ]);
  }

  @override
  Future<void> clearVerificationToken() async {
    await _secure.delete(key: _VERIFICATION_TOKEN_KEY);
  }

  @override
  Future<void> clearUser() async {
    await _prefs.remove(_USER_KEY);
  }

  @override
  Future<bool> get signed async {
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
    await Future.wait([_prefs.clear(), _secure.deleteAll()]);
  }
}
