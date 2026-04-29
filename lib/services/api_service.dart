import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/parcel.dart';
import '../models/notification_model.dart';
import '../models/tracking.dart';
import '../config/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiService {
  static const String baseUrl = 'http://18.60.129.43:8080/api/v1';
  static const String contentType = 'application/json';

  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  final http.Client _client = http.Client();

  Map<String, String> _buildHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': contentType,
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(
    String endpoint, {
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await _client.get(
        url,
        headers: _buildHeaders(token: token),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException(
        'GET request failed for $endpoint',
        originalError: e,
      );
    }
  }

  Future<dynamic> post(
    String endpoint, {
    required dynamic body,
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await _client.post(
        url,
        headers: _buildHeaders(token: token),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException(
        'POST request failed for $endpoint',
        originalError: e,
      );
    }
  }

  Future<dynamic> put(
    String endpoint, {
    required dynamic body,
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await _client.put(
        url,
        headers: _buildHeaders(token: token),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException(
        'PUT request failed for $endpoint',
        originalError: e,
      );
    }
  }

  Future<dynamic> patch(
    String endpoint, {
    required dynamic body,
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await _client.patch(
        url,
        headers: _buildHeaders(token: token),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException(
        'PATCH request failed for $endpoint',
        originalError: e,
      );
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await _client.delete(
        url,
        headers: _buildHeaders(token: token),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException(
        'DELETE request failed for $endpoint',
        originalError: e,
      );
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw ApiException(
        'Unauthorized - token may have expired',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw ApiException(
          'Failed to decode JSON response',
          statusCode: response.statusCode,
          originalError: e,
        );
      }
    }

    try {
      final errorBody = jsonDecode(response.body);
      final message = errorBody['message'] ?? errorBody['error'] ?? 'Unknown error';
      throw ApiException(
        message,
        statusCode: response.statusCode,
      );
    } catch (e) {
      throw ApiException(
        'HTTP ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
        originalError: e,
      );
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.refreshTokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  Future<void> _saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.refreshTokenKey, token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
  }

  /// Get a valid token, auto-refreshing if the current one is expired
  Future<String?> _getValidToken() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return null;

    // Try a quick validation by making a lightweight call
    // Or just return the token and let the caller handle 401
    return token;
  }

  /// Attempt to refresh the access token using the refresh token
  Future<String?> _tryRefreshToken() async {
    try {
      final refreshTk = await _getRefreshToken();
      if (refreshTk == null || refreshTk.isEmpty) return null;

      final url = Uri.parse('$baseUrl${AppConstants.refreshTokenEndpoint}');
      final response = await _client.post(
        url,
        headers: {'Content-Type': contentType, 'Authorization': 'Bearer $refreshTk'},
        body: jsonEncode({}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          final data = body['data'] as Map<String, dynamic>? ?? body;
          final newToken = (data['access_token'] ?? data['token']) as String?;
          final newRefresh = (data['refresh_token']) as String?;
          if (newToken != null && newToken.isNotEmpty) {
            await _saveToken(newToken);
            if (newRefresh != null && newRefresh.isNotEmpty) {
              await _saveRefreshToken(newRefresh);
            }
            return newToken;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Auth Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await post(
        AppConstants.loginEndpoint,
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>? ?? response;
        final token = (data['access_token'] ?? data['token']) as String?;
        final refreshTk = data['refresh_token'] as String?;
        if (token != null && token.isNotEmpty) {
          await _saveToken(token);
        }
        if (refreshTk != null && refreshTk.isNotEmpty) {
          await _saveRefreshToken(refreshTk);
        }
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final token = await _getToken();
      final response = await post(
        AppConstants.refreshTokenEndpoint,
        body: {},
        token: token,
      );

      if (response is Map<String, dynamic>) {
        final newToken = response['token'] as String?;
        if (newToken != null && newToken.isNotEmpty) {
          await _saveToken(newToken);
        }
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<User> getProfile() async {
    try {
      final token = await _getToken();
      final response = await get(
        AppConstants.userProfileEndpoint,
        token: token,
      );

      if (response is Map<String, dynamic>) {
        return User.fromJson(response);
      }
      throw ApiException('Invalid profile response format');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Parcel>> getOrders() async {
    try {
      final token = await _getToken();
      final response = await get(
        '${AppConstants.ordersEndpoint}?page=1&limit=50',
        token: token,
      );

      List<dynamic> ordersList = [];

      if (response is List) {
        ordersList = response;
      } else if (response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is List) {
          // API returns { success: true, data: [...] }
          ordersList = data;
        } else if (data is Map<String, dynamic> && data.containsKey('orders')) {
          // Or { data: { orders: [...] } }
          ordersList = data['orders'] as List<dynamic>? ?? [];
        } else if (response.containsKey('orders')) {
          ordersList = response['orders'] as List<dynamic>? ?? [];
        }
      }

      return ordersList
          .map((item) => Parcel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Parcel> getOrderById(String orderId) async {
    try {
      final token = await _getToken();
      final response = await get(
        '${AppConstants.ordersEndpoint}/$orderId',
        token: token,
      );

      if (response is Map<String, dynamic>) {
        return Parcel.fromJson(response);
      }
      throw ApiException('Invalid order response format');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      final token = await _getToken();
      final response = await post(
        '${AppConstants.ordersEndpoint}/$orderId/cancel',
        body: {},
        token: token,
      );

      return response is Map<String, dynamic> ? response : {};
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    required String packageType,
    required double packageWeight,
    required String receiverName,
    required String receiverPhone,
    required String vehicleType,
    String? senderName,
    String? senderPhone,
    String? notes,
  }) async {
    final orderBody = {
      'pickup_address': pickupAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'delivery_address': deliveryAddress,
      'delivery_lat': deliveryLat,
      'delivery_lng': deliveryLng,
      'package_type': packageType.toLowerCase(),
      'package_weight': packageWeight,
      'receiver_name': receiverName,
      'receiver_phone': receiverPhone,
      'vehicle_type': vehicleType.toLowerCase(),
      if (senderName != null && senderName.isNotEmpty) 'sender_name': senderName,
      if (senderPhone != null && senderPhone.isNotEmpty) 'sender_phone': senderPhone,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    try {
      final token = await _getToken();
      final response = await post(
        AppConstants.ordersEndpoint,
        body: orderBody,
        token: token,
      );

      return response is Map<String, dynamic> ? response : {};
    } on ApiException catch (e) {
      // If 401 (token expired), try refreshing and retry once
      if (e.statusCode == 401) {
        final newToken = await _tryRefreshToken();
        if (newToken != null) {
          final retryResponse = await post(
            AppConstants.ordersEndpoint,
            body: orderBody,
            token: newToken,
          );
          return retryResponse is Map<String, dynamic> ? retryResponse : {};
        }
        throw ApiException('Session expired. Please log out and log in again.', statusCode: 401);
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEstimate({
    required String origin,
    required String destination,
    required double weight,
    required String packageType,
  }) async {
    try {
      final token = await _getToken();
      final response = await post(
        AppConstants.pricingEstimateEndpoint,
        body: {
          'origin': origin,
          'destination': destination,
          'weight': weight,
          'packageType': packageType,
        },
        token: token,
      );

      return response is Map<String, dynamic> ? response : {};
    } catch (e) {
      rethrow;
    }
  }

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final token = await _getToken();
      final response = await get(
        AppConstants.notificationsEndpoint,
        token: token,
      );

      if (response is List) {
        return response
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      if (response is Map<String, dynamic> && response.containsKey('notifications')) {
        final notifications = response['notifications'] as List;
        return notifications
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markNotificationRead(String notificationId) async {
    try {
      final token = await _getToken();
      final response = await post(
        '${AppConstants.notificationsEndpoint}/$notificationId/read',
        body: {},
        token: token,
      );

      return response is Map<String, dynamic> ? response : {};
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TrackingUpdate>> getTracking(String orderId) async {
    try {
      final token = await _getToken();
      final response = await get(
        '${AppConstants.trackingOrderEndpoint}/$orderId',
        token: token,
      );

      if (response is List) {
        return response
            .map((item) => TrackingUpdate.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      if (response is Map<String, dynamic> && response.containsKey('tracking')) {
        final tracking = response['tracking'] as List;
        return tracking
            .map((item) => TrackingUpdate.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _removeToken();
    } catch (e) {
      rethrow;
    }
  }
}
