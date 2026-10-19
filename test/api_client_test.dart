import 'dart:async';
import 'dart:convert';

import 'package:dropzy_mobile/core/api_client.dart';
import 'package:dropzy_mobile/core/token_store.dart';
import 'package:dropzy_mobile/core_api/action_key.dart';
import 'package:dropzy_mobile/core_api/poller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const base = 'http://api.test/api/v1';

http.Response json(int status, Object body, {Map<String, String> headers = const {}}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json', ...headers});

http.Response err(int status, String code, [Map<String, dynamic> details = const {}]) => json(status, {
      'error': {'code': code, 'message': 'server says $code', 'correlationId': 'corr_abc', 'details': details}
    });

ApiClient client(MockClient mock, {TokenStore? store, String access = 'old', String refresh = 'r1'}) {
  final c = ApiClient(client: mock, baseUrl: base, coreMode: true, tokenStore: store, deviceId: 'dev-1');
  c.setTokens(TokenPair(accessToken: access, refreshToken: refresh));
  return c;
}

void main() {
  test('headers: auth, correlation, device, idempotency; public calls omit Authorization', () async {
    final seen = <http.BaseRequest>[];
    final c = client(MockClient((req) async {
      seen.add(req);
      return json(200, {'data': {}});
    }));
    await c.send('POST', '/bookings', body: {'a': 1}, idempotencyKey: 'key-123');
    await c.send('POST', '/auth/otp/request', auth: false, body: {'phone': '9000000001'});
    expect(seen[0].headers['Authorization'], 'Bearer old');
    expect(seen[0].headers['Idempotency-Key'], 'key-123');
    expect(seen[0].headers['X-Device-Id'], 'dev-1');
    expect(RegExp(r'^corr_[0-9a-f]{20}$').hasMatch(seen[0].headers['X-Correlation-Id']!), isTrue);
    expect(seen[1].headers.containsKey('Authorization'), isFalse);
    expect(seen[1].headers.containsKey('Idempotency-Key'), isFalse);
  });

  test('error envelope → typed exception with §6 copy and correlationId', () async {
    final c = client(MockClient((_) async => err(401, 'OTP_INVALID', {'attemptsRemaining': 2})));
    try {
      await c.send('POST', '/auth/otp/verify', auth: false, body: {});
      fail('expected error');
    } on ApiException catch (e) {
      expect(e.statusCode, 401);
      expect(e.code, 'OTP_INVALID');
      expect(e.message, 'Incorrect code. 2 attempts left.');
      expect(e.serverMessage, 'server says OTP_INVALID');
      expect(e.correlationId, 'corr_abc');
      expect(e.details['attemptsRemaining'], 2);
    }
  });

  test('401 UNAUTHENTICATED → refresh → one retry with the SAME Idempotency-Key', () async {
    final store = MemoryTokenStore();
    final keys = <String?>[];
    var refreshes = 0;
    final c = client(MockClient((req) async {
      if (req.url.path.endsWith('/auth/refresh')) {
        refreshes++;
        expect(jsonDecode(req.body), {'refreshToken': 'r1'});
        return json(200, {'data': {'accessToken': 'new', 'refreshToken': 'r2', 'mfaRequired': false}});
      }
      keys.add(req.headers['Idempotency-Key']);
      if (req.headers['Authorization'] == 'Bearer old') return err(401, 'UNAUTHENTICATED');
      return json(201, {'data': {'ok': true}}, headers: {'idempotent-replayed': 'true'});
    }), store: store);
    final res = await c.send('POST', '/payments/intents', body: {'invoiceId': 'i'}, idempotencyKey: 'k-1');
    expect(res.replayed, isTrue);
    expect(refreshes, 1);
    expect(keys, ['k-1', 'k-1']);
    expect(c.accessToken, 'new');
    expect(c.refreshToken, 'r2');
    expect(store.tokens?.refreshToken, 'r2');
  });

  test('concurrent 401s share ONE POST /auth/refresh (single-flight)', () async {
    var refreshes = 0;
    final gate = Completer<void>();
    final c = client(MockClient((req) async {
      if (req.url.path.endsWith('/auth/refresh')) {
        refreshes++;
        await gate.future;
        // Grace-window style response: refreshToken null → keep r1.
        return json(200, {'data': {'accessToken': 'new', 'refreshToken': null}});
      }
      if (req.headers['Authorization'] == 'Bearer old') return err(401, 'UNAUTHENTICATED');
      return json(200, {'data': req.url.path});
    }));
    final futures = [
      c.send('GET', '/me'),
      c.send('GET', '/shipments'),
      c.send('GET', '/me/notifications/unread-count'),
    ];
    await Future<void>.delayed(const Duration(milliseconds: 20));
    gate.complete();
    final results = await Future.wait(futures);
    expect(refreshes, 1);
    expect(results.map((r) => r.data), ['/api/v1/me', '/api/v1/shipments', '/api/v1/me/notifications/unread-count']);
    expect(c.refreshToken, 'r1');
  });

  test('refresh rejected → session ended once, tokens cleared, sessionEnded copy', () async {
    final store = MemoryTokenStore(const TokenPair(accessToken: 'old', refreshToken: 'r1'));
    var ended = 0;
    final c = client(MockClient((req) async {
      if (req.url.path.endsWith('/auth/refresh')) return err(401, 'SESSION_REVOKED');
      return err(401, 'UNAUTHENTICATED');
    }), store: store)
      ..onSessionEnded = () => ended++;
    Future<Object?> capture(Future<ApiResponse> f) async {
      try {
        await f;
        return null;
      } catch (e) {
        return e;
      }
    }

    final results = await Future.wait([capture(c.send('GET', '/me')), capture(c.send('GET', '/shipments'))]);
    for (final e in results) {
      expect(e, isA<ApiException>());
      expect((e as ApiException).message, 'Your session has ended. Please log in again.');
    }
    expect(ended, 1);
    expect(c.hasSession, isFalse);
    expect(store.tokens, isNull);
  });

  test('401 SESSION_REVOKED never refreshes', () async {
    var refreshes = 0;
    var ended = 0;
    final c = client(MockClient((req) async {
      if (req.url.path.endsWith('/auth/refresh')) refreshes++;
      return err(401, 'SESSION_REVOKED');
    }))
      ..onSessionEnded = () => ended++;
    await expectLater(c.send('GET', '/me'), throwsA(isA<ApiException>()));
    expect(refreshes, 0);
    expect(ended, 1);
  });

  test('timeouts surface as network errors (outcome unknown)', () async {
    final c = ApiClient(
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return json(200, {});
      }),
      baseUrl: base,
      coreMode: true,
      timeout: const Duration(milliseconds: 20),
    );
    try {
      await c.send('GET', '/me', auth: false);
      fail('expected timeout');
    } on ApiException catch (e) {
      expect(e.isNetwork, isTrue);
      expect(e.outcomeUnknown, isTrue);
      expect(e.message, 'Cannot reach the server. Check your connection.');
    }
  });

  test('multipart upload sends fields and file with idempotency key', () async {
    late http.BaseRequest seen;
    String? body;
    final c = client(MockClient((req) async {
      seen = req;
      body = req.body;
      return json(201, {'data': {'id': 'ev1'}});
    }));
    final r = await c.upload('/evidence',
        bytes: [1, 2, 3], filename: 'p.jpg', fields: {'kind': 'DISPUTE_ATTACHMENT'}, idempotencyKey: 'up-1');
    expect(r.dataMap['id'], 'ev1');
    expect(seen.headers['Idempotency-Key'], 'up-1');
    expect(seen.headers['content-type'], startsWith('multipart/form-data'));
    expect(body, contains('DISPUTE_ATTACHMENT'));
    expect(body, contains('filename="p.jpg"'));
  });

  test('legacy mode keeps the old 401 behaviour (no refresh)', () async {
    var unauthorized = 0;
    var refreshes = 0;
    final c = ApiClient(
      client: MockClient((req) async {
        if (req.url.path.endsWith('/auth/refresh')) refreshes++;
        return json(401, {'message': 'nope'});
      }),
      baseUrl: base,
      coreMode: false,
    )
      ..setToken('t')
      ..onUnauthorized = () => unauthorized++;
    await expectLater(c.get('/shipments'), throwsA(isA<ApiException>()));
    expect(unauthorized, 1);
    expect(refreshes, 0);
  });

  group('ActionKey (one key per user action)', () {
    test('reused after unknown outcome, released after success / definitive error', () async {
      var n = 0;
      final key = ActionKey(() => 'k${++n}');
      final used = <String>[];
      await expectLater(key.run((k) async {
        used.add(k);
        throw ApiException(0, 'net', code: 'NETWORK');
      }), throwsA(isA<ApiException>()));
      await key.run((k) async => used.add(k)); // retry of the same action
      await key.run((k) async => used.add(k)); // new action
      await expectLater(key.run((k) async {
        used.add(k);
        throw ApiException(409, 'x', code: 'INVOICE_NOT_PAYABLE');
      }), throwsA(isA<ApiException>()));
      await key.run((k) async => used.add(k));
      expect(used, ['k1', 'k1', 'k2', 'k3', 'k4']);
    });
    test('reset() starts a new action', () async {
      var n = 0;
      final key = ActionKey(() => 'k${++n}');
      expect(key.current, 'k1');
      key.reset();
      expect(key.current, 'k2');
    });
    test('default keys are uuid v4', () {
      expect(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(ActionKey().current), isTrue);
    });
  });

  test('poll back-off doubles up to 60 s', () {
    const base = Duration(seconds: 10);
    const cap = Duration(seconds: 60);
    expect(Poller.backoffDelay(base, 0, cap), base);
    expect(Poller.backoffDelay(base, 1, cap), const Duration(seconds: 20));
    expect(Poller.backoffDelay(base, 2, cap), const Duration(seconds: 40));
    expect(Poller.backoffDelay(base, 3, cap), cap);
    expect(Poller.backoffDelay(const Duration(seconds: 3), 1, cap), const Duration(seconds: 6));
  });
}
