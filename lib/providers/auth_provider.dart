import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../config/constants.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _user;
  String? _token;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      final userData = prefs.getString(AppConstants.userKey);

      if (token != null && token.isNotEmpty) {
        _token = token;
        if (userData != null) {
          _user = User.fromJson(
            Map<String, dynamic>.from(
              Uri.splitQueryString(userData).entries.fold(
                    <String, dynamic>{},
                    (map, entry) => {...map, entry.key: entry.value},
                  ),
            ),
          );
        }
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
      _error = null;
    } catch (e) {
      _isAuthenticated = false;
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);

      if (response is Map<String, dynamic>) {
        // API wraps response in 'data' key
        final data = response['data'] as Map<String, dynamic>? ?? response;
        final token = (data['access_token'] ?? data['token']) as String?;
        final userData = data['user'] as Map<String, dynamic>?;

        if (token != null && token.isNotEmpty) {
          _token = token;
          if (userData != null) {
            _user = User.fromJson(userData);
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.tokenKey, token);
          if (userData != null) {
            await prefs.setString(
              AppConstants.userKey,
              userData.toString(),
            );
          }
          await prefs.setBool(AppConstants.isLoggedInKey, true);

          _isAuthenticated = true;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _error = 'Login failed: Invalid response';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userKey);
      await prefs.remove(AppConstants.isLoggedInKey);

      _user = null;
      _token = null;
      _isAuthenticated = false;
      _error = null;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? city,
  }) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      _user = _user!.copyWith(
        firstName: firstName ?? _user!.firstName,
        lastName: lastName ?? _user!.lastName,
        phone: phone ?? _user!.phone,
        city: city ?? _user!.city,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.userKey,
        _user!.toJson().toString(),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshToken() async {
    try {
      final response = await _apiService.refreshToken();

      if (response is Map<String, dynamic>) {
        final newToken = response['token'] as String?;

        if (newToken != null && newToken.isNotEmpty) {
          _token = newToken;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.tokenKey, newToken);

          notifyListeners();
          return true;
        }
      }

      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
