import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'constants.dart';
import 'error_copy.dart';
import 'token_store.dart';

/// Thrown for any non-2xx response or transport failure.
///
/// [message] is always display-ready: in core mode it is the CLIENT_CONTRACTS
/// §6 copy keyed by [code] (fallback: the server's `error.message`).
/// [statusCode] 0 means the server could not be reached / timed out.
class ApiException implements Exception {
  ApiException(
    this.statusCode,
    this.message, {
    this.code,
    this.serverMessage,
    this.details = const {},
    this.correlationId,
  });

  final int statusCode;
  final String message;

  /// Core `error.code` (e.g. `OTP_INVALID`), `NETWORK` for transport errors.
  final String? code;
  final String? serverMessage;
  final Map<String, dynamic> details;

  /// Shown on long-press / "Details" for support (§1.2).
  final String? correlationId;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => statusCode == 0;

  /// The outcome of the command is unknown (no response, timeout, 5xx, or the
  /// same key is still being processed) — retrying the same user action with
  /// the same Idempotency-Key is safe and returns the original result.
  bool get outcomeUnknown =>
      statusCode == 0 ||
      statusCode >= 500 && code != 'PAYMENT_PROVIDER_UNAVAILABLE' ||
      (code == 'IDEMPOTENCY_CONFLICT' && details['reason'] == 'IN_PROGRESS');

  @override
  String toString() => message;
}

/// Raw successful response. Core endpoints wrap payloads in `{data, meta}`.
class ApiResponse {
  ApiResponse(this.statusCode, this.body, this.headers);
  final int statusCode;
  final dynamic body;
  final Map<String, String> headers;

  /// `Idempotent-Replayed: true` — a stored result of an earlier identical
  /// command; treated as success (§1.4).
  bool get replayed => headers['idempotent-replayed']?.toLowerCase() == 'true';

  dynamic get data => body is Map ? (body as Map)['data'] : null;

  Map<String, dynamic> get dataMap {
    final d = data;
    return d is Map ? d.cast<String, dynamic>() : <String, dynamic>{};
  }

  List<Map<String, dynamic>> get dataList {
    final d = data;
    if (d is! List) return const [];
    return d.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  Map<String, dynamic> get meta {
    final m = body is Map ? (body as Map)['meta'] : null;
    return m is Map ? m.cast<String, dynamic>() : <String, dynamic>{};
  }
}

class _MultipartSpec {
  _MultipartSpec(this.field, this.bytes, this.filename, this.contentType, this.fields);
  final String field;
  final List<int> bytes;
  final String filename;
  final String contentType;
  final Map<String, String> fields;
}

enum _RefreshOutcome { refreshed, rejected, unreachable }

/// HTTP wrapper around the Dropzy Go backend.
///
/// Legacy mode (CORE_API=false) keeps the old behaviour: Bearer token,
/// `{data}` envelope, 401 → [onUnauthorized].
///
/// Core mode (CORE_API=true, CLIENT_CONTRACTS.md §1): 15 s timeouts,
/// `Idempotency-Key` on commands, `X-Correlation-Id` + `X-Device-Id` on every
/// request, `{"error":{code,message,details,correlationId}}` parsing with
/// §6 copy, and on `401 UNAUTHENTICATED` a single-flight `POST /auth/refresh`
/// (concurrent 401s share one refresh) followed by exactly one retry of the
/// original request with the same Idempotency-Key. `SESSION_REVOKED` or a
/// rejected refresh ends the session via [onSessionEnded].
class ApiClient {
  ApiClient({
    http.Client? client,
    String? baseUrl,
    bool? coreMode,
    this.timeout = const Duration(seconds: 15),
    this.tokenStore,
    this.deviceId,
  })  : _http = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        coreMode = coreMode ?? AppConfig.coreApi;

  final http.Client _http;
  final String baseUrl;
  final bool coreMode;
  final Duration timeout;

  /// Persists rotated tokens after a refresh (core mode).
  TokenStore? tokenStore;

  /// Stable install id, sent as `X-Device-Id` in core mode.
  String? deviceId;

  String? _token;
  String? _refreshToken;
  Future<_RefreshOutcome>? _refreshing;

  /// Legacy: called on any 401 so the app can log the user out.
  void Function()? onUnauthorized;

  /// Core: session revoked / refresh failed → back to login with
  /// "Your session has ended. Please log in again."
  void Function()? onSessionEnded;

  void setToken(String? token) => _token = token;

  void setTokens(TokenPair? tokens) {
    _token = tokens?.accessToken;
    _refreshToken = tokens?.refreshToken;
  }

  String? get accessToken => _token;
  String? get refreshToken => _refreshToken;
  bool get hasSession => _token != null;

  // ─── Convenience verbs (return the decoded JSON body) ───

  Future<dynamic> get(String endpoint, {Map<String, String>? query, bool auth = true}) async =>
      (await send('GET', endpoint, query: query, auth: auth)).body;

  Future<dynamic> post(String endpoint, {Object? body, bool auth = true, String? idempotencyKey}) async =>
      (await send('POST', endpoint, body: body, auth: auth, idempotencyKey: idempotencyKey)).body;

  Future<dynamic> put(String endpoint, {Object? body, String? idempotencyKey}) async =>
      (await send('PUT', endpoint, body: body, idempotencyKey: idempotencyKey)).body;

  Future<dynamic> patch(String endpoint, {Object? body, String? idempotencyKey}) async =>
      (await send('PATCH', endpoint, body: body, idempotencyKey: idempotencyKey)).body;

  Future<dynamic> delete(String endpoint, {String? idempotencyKey}) async =>
      (await send('DELETE', endpoint, idempotencyKey: idempotencyKey)).body;

  /// multipart/form-data upload (e.g. `POST /evidence`).
  Future<ApiResponse> upload(
    String endpoint, {
    required List<int> bytes,
    required String filename,
    String field = 'file',
    String contentType = 'image/jpeg',
    Map<String, String> fields = const {},
    String? idempotencyKey,
  }) =>
      send('POST', endpoint,
          idempotencyKey: idempotencyKey,
          multipart: _MultipartSpec(field, bytes, filename, contentType, fields));

  // ─── Core send ───

  Future<ApiResponse> send(
    String method,
    String endpoint, {
    Object? body,
    Map<String, String>? query,
    bool auth = true,
    String? idempotencyKey,
    // ignore: library_private_types_in_public_api
    _MultipartSpec? multipart,
  }) async {
    final usedToken = auth ? _token : null;
    var res = await _execute(method, endpoint,
        jsonBody: body, query: query, token: usedToken, idempotencyKey: idempotencyKey, multipart: multipart);

    if (res.statusCode == 401) {
      if (!coreMode) {
        onUnauthorized?.call();
        throw ApiException(401, 'Session expired. Please sign in again.');
      }
      if (usedToken != null) {
        final err = _toException(res);
        if (err.code == 'SESSION_REVOKED') {
          await _endSession();
          throw _sessionEnded(err);
        }
        final outcome = await _ensureFresh(usedToken);
        switch (outcome) {
          case _RefreshOutcome.unreachable:
            throw ApiException(0, ErrorCopy.network, code: 'NETWORK');
          case _RefreshOutcome.rejected:
            await _endSession();
            throw _sessionEnded(err);
          case _RefreshOutcome.refreshed:
            // Retry exactly once, same Idempotency-Key (same user action).
            res = await _execute(method, endpoint,
                jsonBody: body,
                query: query,
                token: _token,
                idempotencyKey: idempotencyKey,
                multipart: multipart);
            if (res.statusCode == 401) {
              final again = _toException(res);
              await _endSession();
              throw _sessionEnded(again);
            }
        }
      }
    }

    if (res.statusCode < 200 || res.statusCode >= 300) throw _toException(res);
    return ApiResponse(res.statusCode, _decode(res.body), res.headers);
  }

  /// Single-flight refresh: all callers that saw a 401 for the same stale
  /// access token await the same `POST /auth/refresh`.
  Future<_RefreshOutcome> _ensureFresh(String staleToken) {
    if (_token != null && _token != staleToken) {
      return Future.value(_RefreshOutcome.refreshed); // someone already rotated
    }
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<_RefreshOutcome> _doRefresh() async {
    final rt = _refreshToken;
    if (rt == null || rt.isEmpty) return _RefreshOutcome.rejected;
    http.Response res;
    try {
      res = await _execute('POST', '/auth/refresh', jsonBody: {'refreshToken': rt}, token: null);
    } on ApiException {
      return _RefreshOutcome.unreachable;
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = _decode(res.body);
      final data = decoded is Map ? decoded['data'] : null;
      final access = data is Map ? data['accessToken'] : null;
      if (access is! String || access.isEmpty) return _RefreshOutcome.rejected;
      final newRefresh = data['refreshToken'];
      _token = access;
      // Within the server's reuse-grace window refreshToken is null: keep ours.
      if (newRefresh is String && newRefresh.isNotEmpty) _refreshToken = newRefresh;
      try {
        await tokenStore?.write(TokenPair(accessToken: access, refreshToken: _refreshToken));
      } catch (_) {/* keep the in-memory session */}
      return _RefreshOutcome.refreshed;
    }
    if (res.statusCode == 429 || res.statusCode >= 500) return _RefreshOutcome.unreachable;
    return _RefreshOutcome.rejected;
  }

  Future<void> _endSession() async {
    final hadSession = _token != null || _refreshToken != null;
    _token = null;
    _refreshToken = null;
    if (!hadSession) return;
    try {
      await tokenStore?.clear();
    } catch (_) {}
    onSessionEnded?.call();
  }

  ApiException _sessionEnded(ApiException cause) => ApiException(
        401,
        ErrorCopy.sessionEnded,
        code: 'SESSION_REVOKED',
        serverMessage: cause.serverMessage,
        details: cause.details,
        correlationId: cause.correlationId,
      );

  Uri _uri(String endpoint, Map<String, String>? query) {
    final uri = Uri.parse('$baseUrl$endpoint');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  Map<String, String> _headers({String? token, String? idempotencyKey, bool json = true}) => {
        if (json) 'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Omitted entirely on public calls (no empty Authorization header).
        if (token != null) 'Authorization': 'Bearer $token',
        if (coreMode) 'X-Correlation-Id': newCorrelationId(),
        if (coreMode && deviceId != null) 'X-Device-Id': deviceId!,
        if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
      };

  Future<http.Response> _execute(
    String method,
    String endpoint, {
    Object? jsonBody,
    Map<String, String>? query,
    String? token,
    String? idempotencyKey,
    _MultipartSpec? multipart,
  }) async {
    final uri = _uri(endpoint, query);
    final http.BaseRequest req;
    if (multipart != null) {
      final m = http.MultipartRequest(method, uri);
      m.fields.addAll(multipart.fields);
      m.files.add(http.MultipartFile.fromBytes(
        multipart.field,
        multipart.bytes,
        filename: multipart.filename,
        contentType: MediaType.parse(multipart.contentType),
      ));
      m.headers.addAll(_headers(token: token, idempotencyKey: idempotencyKey, json: false));
      req = m;
    } else {
      final r = http.Request(method, uri);
      r.headers.addAll(_headers(token: token, idempotencyKey: idempotencyKey));
      if (jsonBody != null) r.body = jsonEncode(jsonBody);
      req = r;
    }
    try {
      final streamed = await _http.send(req).timeout(timeout);
      return await http.Response.fromStream(streamed).timeout(timeout);
    } catch (_) {
      throw ApiException(0, ErrorCopy.network, code: 'NETWORK');
    }
  }

  ApiException _toException(http.Response res) {
    final decoded = _decode(res.body);
    String? code;
    String? serverMessage;
    String? correlationId;
    var details = <String, dynamic>{};
    if (decoded is Map && decoded['error'] is Map) {
      final e = (decoded['error'] as Map).cast<String, dynamic>();
      code = e['code']?.toString();
      serverMessage = e['message']?.toString();
      correlationId = e['correlationId']?.toString();
      if (e['details'] is Map) details = (e['details'] as Map).cast<String, dynamic>();
    } else if (decoded is Map) {
      if (decoded['message'] is String) serverMessage = decoded['message'] as String;
      if (decoded['error'] is String) serverMessage ??= decoded['error'] as String;
    }
    correlationId ??= res.headers['x-correlation-id'];
    final message = coreMode
        ? ErrorCopy.resolve(code: code, details: details, serverMessage: serverMessage)
        : (serverMessage ?? 'Request failed (${res.statusCode})');
    return ApiException(res.statusCode, message,
        code: code, serverMessage: serverMessage, details: details, correlationId: correlationId);
  }

  dynamic _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return {'message': body};
    }
  }

  static final Random _rand = Random.secure();

  /// `corr_` + 20 lowercase hex chars (§1.5).
  static String newCorrelationId() {
    final b = StringBuffer('corr_');
    for (var i = 0; i < 20; i++) {
      b.write(_rand.nextInt(16).toRadixString(16));
    }
    return b.toString();
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
