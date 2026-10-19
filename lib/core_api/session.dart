import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/error_copy.dart';
import '../core/token_store.dart';
import 'api.dart';
import 'models.dart';

enum CoreAuthStatus { unknown, unauthenticated, authenticated }

/// Session state for CORE_API builds (C1–C3, C19).
class CoreSession extends ChangeNotifier {
  CoreSession({required this.api, required this.tokens, this.deviceId}) {
    api.client.tokenStore = tokens;
    api.client.onSessionEnded = _sessionEnded;
  }

  final CoreApi api;
  final TokenStore tokens;
  final String? deviceId;

  CoreAuthStatus status = CoreAuthStatus.unknown;
  Me? me;

  /// Splash could not reach the server (shows retry).
  String? bootstrapError;

  /// After a first login without a name → name prompt.
  bool needsName = false;

  /// One-shot message for the login screen ("Your session has ended…").
  String? _notice;

  String? takeNotice() {
    final n = _notice;
    _notice = null;
    return n;
  }

  /// C1: restore tokens from secure storage and `GET /me`.
  Future<void> bootstrap() async {
    bootstrapError = null;
    if (status != CoreAuthStatus.unknown) {
      status = CoreAuthStatus.unknown;
      notifyListeners();
    }
    final saved = await tokens.read();
    if (saved == null) {
      status = CoreAuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    api.client.setTokens(saved);
    try {
      me = await api.me();
      status = CoreAuthStatus.authenticated;
    } on ApiException catch (e) {
      if (e.isUnauthorized || e.statusCode == 403 || e.statusCode == 404) {
        await _clear();
        status = CoreAuthStatus.unauthenticated;
      } else {
        bootstrapError = e.message;
      }
    }
    notifyListeners();
  }

  /// C2 / resend.
  Future<OtpChallenge> requestOtp(String phone) => api.requestOtp(phone);

  /// C3.
  Future<AuthResult> verifyOtp({required OtpChallenge challenge, required String phone, required String code}) async {
    final r = await api.verifyOtp(
      challengeId: challenge.challengeId,
      phone: phone,
      code: code,
      deviceId: deviceId,
      platform: _platform(),
      deviceName: 'Dropzy customer app',
    );
    final access = r.accessToken;
    if (r.mfaRequired || access == null || access.isEmpty) {
      throw ApiException(401, 'This account cannot sign in to the customer app.', code: 'MFA_REQUIRED');
    }
    final pair = TokenPair(accessToken: access, refreshToken: r.refreshToken);
    api.client.setTokens(pair);
    await tokens.write(pair);
    me = r.user;
    if (me == null) {
      try {
        me = await api.me();
      } catch (_) {/* shown as "Customer" until profile loads */}
    }
    needsName = r.isNewUser || (me?.name ?? '').trim().isEmpty;
    status = CoreAuthStatus.authenticated;
    notifyListeners();
    return r;
  }

  Future<void> saveName(String name, {required String idempotencyKey}) async {
    me = await api.updateMe(name: name, idempotencyKey: idempotencyKey);
    needsName = false;
    notifyListeners();
  }

  void skipNamePrompt() {
    needsName = false;
    notifyListeners();
  }

  Future<void> reloadMe() async {
    me = await api.me();
    notifyListeners();
  }

  void setMe(Me m) {
    me = m;
    notifyListeners();
  }

  /// C19 logout: revoke the server session, then forget local tokens.
  Future<void> logout() async {
    try {
      if (api.client.hasSession) await api.logout();
    } catch (_) {/* local logout proceeds */}
    await _clear();
    me = null;
    needsName = false;
    status = CoreAuthStatus.unauthenticated;
    notifyListeners();
  }

  void _sessionEnded() {
    me = null;
    needsName = false;
    _notice = ErrorCopy.sessionEnded;
    status = CoreAuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _clear() async {
    api.client.setTokens(null);
    await tokens.clear();
  }

  static String _platform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'other';
    }
  }
}
