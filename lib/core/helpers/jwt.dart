import 'dart:convert';

bool isJWTExpired(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;

    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );

    final exp = (jsonDecode(payload) as Map<String, dynamic>)['exp'] as int?;
    if (exp == null) return false;

    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp;
  } catch (_) {
    return true;
  }
}
