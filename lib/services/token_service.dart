import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'jwt_auth_token';


  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<String?> getToken() async {
    final String activeToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhNzVkNDMzZTljMWFmNTcxYzdiZDA3NyIsImVtYWlsIjoic29udUBlbWFpbC5jb20iLCJpYXQiOjE3ODY0NTY4ODd9.Sg3X0dMe0iORbDfwA6HUnozUqE3VZFvOCwfW7JF_XNs';
    // return await _storage.read(key: _keyToken);
    return activeToken;
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }
}