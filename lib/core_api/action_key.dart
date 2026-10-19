import 'package:uuid/uuid.dart';

import '../core/api_client.dart';

/// Idempotency key for one *user action* (CLIENT_CONTRACTS.md §1.4).
///
/// The UUID v4 is created when the action is first attempted (button tap /
/// queued item) and reused for every retry of that same action. It is
/// released — so the next tap is a new action with a new key — when the
/// command succeeds or fails definitively (4xx domain error). After an
/// unknown outcome (no response, timeout, 5xx) the key is kept so that a
/// retry is replayed by the server instead of executed twice.
class ActionKey {
  ActionKey([String Function()? generator]) : _gen = generator ?? (() => const Uuid().v4());

  final String Function() _gen;
  String? _key;

  /// The key of the in-flight / last-unknown action, or null.
  String? get pending => _key;

  /// The key for the current action (creates one if none).
  String get current => _key ??= _gen();

  /// Forget the current key (inputs changed → a retry would be a new action).
  void reset() => _key = null;

  Future<T> run<T>(Future<T> Function(String key) command) async {
    final key = current;
    try {
      final result = await command(key);
      if (_key == key) _key = null;
      return result;
    } on ApiException catch (e) {
      if (!e.outcomeUnknown && _key == key) _key = null;
      rethrow;
    }
  }
}

/// A fresh key for one-shot commands with no retry affordance.
String newIdempotencyKey() => const Uuid().v4();
