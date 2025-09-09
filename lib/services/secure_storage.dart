import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const _storage = FlutterSecureStorage();
  static const _kUserId = 'USER_ID';
  static const _kUserPw = 'USER_PW';

  static Future<void> saveCreds(String userId, String userPw) async {
    await _storage.write(key: _kUserId, value: userId);
    await _storage.write(key: _kUserPw, value: userPw);
  }

  static Future<(String?, String?)> readCreds() async {
    final id = await _storage.read(key: _kUserId);
    final pw = await _storage.read(key: _kUserPw);
    return (id, pw);
  }

  static Future<Map<String, String?>> getCreds() async {
    final id = await _storage.read(key: _kUserId);
    final pw = await _storage.read(key: _kUserPw);
    return {
      'id': id,
      'pw': pw,
    };
  }

  static Future<bool> hasCreds() async {
    final (id, pw) = await readCreds();
    return (id != null && id.isNotEmpty) && (pw != null && pw.isNotEmpty);
  }

  static Future<void> clearCreds() async {
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kUserPw);
  }
}
