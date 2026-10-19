import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'constants.dart';

/// Access + refresh token pair.
class TokenPair {
  const TokenPair({required this.accessToken, this.refreshToken});
  final String accessToken;
  final String? refreshToken;
}

/// Where the session tokens are persisted.
abstract class TokenStore {
  Future<TokenPair?> read();
  Future<void> write(TokenPair tokens);
  Future<void> clear();
}

/// CORE_API builds: tokens in the platform keystore / keychain
/// (CLIENT_CONTRACTS.md §1.3).
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<TokenPair?> read() async {
    try {
      final access = await _storage.read(key: AppConfig.kAccessToken);
      if (access == null || access.isEmpty) return null;
      final refresh = await _storage.read(key: AppConfig.kRefreshToken);
      return TokenPair(accessToken: access, refreshToken: refresh);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(TokenPair tokens) async {
    await _storage.write(key: AppConfig.kAccessToken, value: tokens.accessToken);
    if (tokens.refreshToken != null) {
      await _storage.write(key: AppConfig.kRefreshToken, value: tokens.refreshToken);
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: AppConfig.kAccessToken);
      await _storage.delete(key: AppConfig.kRefreshToken);
    } catch (_) {/* nothing stored */}
  }
}

/// Test / in-memory store.
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.tokens]);
  TokenPair? tokens;
  int writes = 0;

  @override
  Future<TokenPair?> read() async => tokens;

  @override
  Future<void> write(TokenPair t) async {
    writes++;
    tokens = TokenPair(
      accessToken: t.accessToken,
      refreshToken: t.refreshToken ?? tokens?.refreshToken,
    );
  }

  @override
  Future<void> clear() async => tokens = null;
}

/// Stable per-install UUID sent as `X-Device-Id` (CLIENT_CONTRACTS.md §1.5).
class DeviceIdentity {
  DeviceIdentity._();

  static Future<String> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(AppConfig.kDeviceId);
      if (existing != null && existing.isNotEmpty) return existing;
      final id = const Uuid().v4();
      await prefs.setString(AppConfig.kDeviceId, id);
      return id;
    } catch (_) {
      return const Uuid().v4();
    }
  }
}
