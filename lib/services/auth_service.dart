import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/user.dart';

class AuthResult {
  final String accessToken;
  final String? refreshToken;
  final AppUser? user;
  AuthResult(this.accessToken, this.refreshToken, this.user);
}

/// Auth against the Dropzy Go backend.
///
/// The official app signs in with **mobile + OTP** (demo OTP `1234`). The
/// deployed OTP endpoints aren't documented in the repo, so [requestOtp] /
/// [verifyOtp] try the likely paths and fall back to the confirmed-working
/// register/login endpoints (phone-derived account) so the demo authenticates
/// for real and gets a valid JWT for the rest of the API.
class AuthService {
  AuthService(this._api);
  final ApiClient _api;

  // ─── OTP flow ───
  Future<void> requestOtp(String mobile) async {
    for (final ep in const ['/auth/otp', '/auth/request-otp', '/auth/send-otp']) {
      try {
        await _api.post(ep, auth: false, body: {'mobile': mobile});
        return;
      } catch (_) {/* try next / fall through to demo */}
    }
    // No matching endpoint — proceed anyway; the demo OTP is 1234.
  }

  Future<AuthResult> verifyOtp(String mobile, String otp) async {
    for (final ep in const ['/auth/verify-otp', '/auth/otp/verify', '/auth/verify']) {
      try {
        final res = await _api.post(ep, auth: false, body: {'mobile': mobile, 'otp': otp});
        final r = _tokenFrom(res);
        if (r != null) return r;
      } catch (_) {/* try next */}
    }
    // Demo fallback: accept 1234 and obtain a real session.
    if (otp == AppConfig.demoOtp) return _demoAuth(mobile);
    throw ApiException(401, 'Invalid OTP. Try ${AppConfig.demoOtp} for the demo.');
  }

  /// Maps a phone number to a stable account and signs in (registering once
  /// if needed) so the demo OTP yields a real backend token.
  Future<AuthResult> _demoAuth(String mobile) async {
    final email = '$mobile@dropzy.mobile';
    final password = 'Dropzy#$mobile';
    try {
      return await login(email, password);
    } catch (_) {
      await register(
        firstName: 'Customer',
        lastName: 'User',
        email: email,
        phone: mobile,
        password: password,
      );
      return await login(email, password);
    }
  }

  // ─── Email / password (used under the hood + as fallback) ───
  Future<AuthResult> login(String email, String password) async {
    final res = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
    final r = _tokenFrom(res);
    if (r == null) throw ApiException(500, 'No access token received from server.');
    return r;
  }

  Future<AuthResult?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    String? city,
  }) async {
    final res = await _api.post(
      '/auth/register',
      auth: false,
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': 'customer',
        if (city != null && city.isNotEmpty) 'city': city,
      },
    );
    return _tokenFrom(res);
  }

  // ─── Profile ───
  Future<AppUser> profile() async {
    final res = await _api.get('/users/profile');
    return AppUser.fromJson((unwrap(res) as Map).cast<String, dynamic>());
  }

  Future<AppUser> updateProfile(Map<String, dynamic> body) async {
    final res = await _api.put('/users/profile', body: body);
    return AppUser.fromJson((unwrap(res) as Map).cast<String, dynamic>());
  }

  AuthResult? _tokenFrom(dynamic res) {
    final data = unwrap(res);
    if (data is! Map) return null;
    final token = data['access_token'] ?? data['accessToken'] ?? data['token'];
    if (token == null) return null;
    final rawUser = data['user'] ?? data;
    return AuthResult(
      '$token',
      (data['refresh_token'] ?? data['refreshToken'])?.toString(),
      rawUser is Map ? AppUser.fromJson(rawUser.cast<String, dynamic>()) : null,
    );
  }
}
