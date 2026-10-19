import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/user.dart';
import 'services.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Owns the session: OTP sign-in, token persistence, current user.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._services) {
    _services.api.onUnauthorized = _forceLogout;
  }

  final Services _services;

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  String? mobile;
  String? _token;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConfig.kAccessToken);
    mobile = prefs.getString(AppConfig.kMobile);
    if (saved == null || saved.isEmpty) {
      _set(AuthStatus.unauthenticated);
      return;
    }
    _token = saved;
    _services.api.setToken(saved);
    try {
      user = await _services.auth.profile();
      _set(AuthStatus.authenticated);
    } catch (_) {
      await _clearStorage();
      _set(AuthStatus.unauthenticated);
    }
  }

  /// Step 1 — request an OTP for [mobile].
  Future<void> requestOtp(String mobileNumber) async {
    mobile = mobileNumber.trim();
    await _services.auth.requestOtp(mobile!);
  }

  /// Step 2 — verify the OTP and start the session.
  Future<void> verifyOtp(String otp) async {
    final result = await _services.auth.verifyOtp(mobile ?? '', otp.trim());
    _token = result.accessToken;
    _services.api.setToken(_token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.kAccessToken, result.accessToken);
    if (result.refreshToken != null) {
      await prefs.setString(AppConfig.kRefreshToken, result.refreshToken!);
    }
    if (mobile != null) await prefs.setString(AppConfig.kMobile, mobile!);

    user = result.user ?? await _safeProfile();
    _set(AuthStatus.authenticated);
  }

  Future<AppUser?> _safeProfile() async {
    try {
      return await _services.auth.profile();
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshProfile() async {
    if (!isAuthenticated) return;
    final u = await _safeProfile();
    if (u != null) {
      user = u;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _clearStorage();
    _token = null;
    user = null;
    _services.api.setToken(null);
    _set(AuthStatus.unauthenticated);
  }

  void _forceLogout() {
    _clearStorage();
    _token = null;
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.kAccessToken);
    await prefs.remove(AppConfig.kRefreshToken);
  }

  void _set(AuthStatus s) {
    status = s;
    notifyListeners();
  }
}
