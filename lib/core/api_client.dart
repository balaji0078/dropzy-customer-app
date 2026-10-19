import 'dart:convert';
import 'package:http/http.dart' as http;

import 'constants.dart';

/// Thrown for any non-2xx response. [statusCode] 401 signals the session
/// should be cleared (handled by AuthProvider).
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Thin HTTP wrapper around the Dropzy Go backend.
/// Mirrors lib/api.ts in the admin repo: Bearer token, JSON body,
/// unwraps `{ data: ... }` envelopes, surfaces `message` on errors.
class ApiClient {
  ApiClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;
  String? _token;

  /// Called on 401 so the app can log the user out.
  void Function()? onUnauthorized;

  void setToken(String? token) => _token = token;

  Uri _uri(String endpoint) => Uri.parse('${AppConfig.apiBaseUrl}$endpoint');

  Map<String, String> _headers([Map<String, String>? extra]) => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
        ...?extra,
      };

  Future<dynamic> get(String endpoint) =>
      _send(() => _http.get(_uri(endpoint), headers: _headers()));

  Future<dynamic> post(String endpoint, {Object? body, bool auth = true}) =>
      _send(() => _http.post(
            _uri(endpoint),
            headers: _headers(auth ? null : {'Authorization': ''}),
            body: body == null ? null : jsonEncode(body),
          ));

  Future<dynamic> put(String endpoint, {Object? body}) => _send(() =>
      _http.put(_uri(endpoint), headers: _headers(), body: jsonEncode(body)));

  Future<dynamic> patch(String endpoint, {Object? body}) => _send(() =>
      _http.patch(_uri(endpoint),
          headers: _headers(), body: body == null ? null : jsonEncode(body)));

  Future<dynamic> _send(Future<http.Response> Function() run) async {
    late http.Response res;
    try {
      res = await run();
    } catch (_) {
      throw ApiException(0, 'Cannot reach the server. Check your connection.');
    }

    if (res.statusCode == 401) {
      onUnauthorized?.call();
      throw ApiException(401, 'Session expired. Please sign in again.');
    }

    final decoded = _decode(res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = (decoded is Map && decoded['message'] is String)
          ? decoded['message'] as String
          : 'Request failed (${res.statusCode})';
      throw ApiException(res.statusCode, msg);
    }
    return decoded;
  }

  dynamic _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return {'message': body};
    }
  }
}

/// Unwraps the common Go response envelopes: `{data: ...}` / `{user: ...}`.
dynamic unwrap(dynamic res) {
  if (res is Map) {
    if (res.containsKey('data')) return res['data'];
    if (res.containsKey('user')) return res['user'];
  }
  return res;
}
