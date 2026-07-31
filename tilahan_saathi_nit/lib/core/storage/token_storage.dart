import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure, on-device storage for the backend access token issued by
/// `POST /auth/login`. Its presence is what drives auto-login on app start.
class TokenStorage {
  const TokenStorage();

  static const _accessTokenKey = 'access_token';
  static const _storage = FlutterSecureStorage();

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  /// Wipes everything in secure storage, not just the access token, so
  /// logout never leaves stale data behind for the next session.
  Future<void> clear() => _storage.deleteAll();
}




const tokenStorage = TokenStorage();
