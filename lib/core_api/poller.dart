import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

/// Lifecycle-aware polling (CLIENT_CONTRACTS.md §1.9):
/// * pauses while the app is backgrounded and resumes with one immediate
///   fetch when it returns to the foreground;
/// * the interval may change between ticks (e.g. 3 s while verifying);
/// * after consecutive failures the delay doubles, capped at [maxBackoff].
class Poller with WidgetsBindingObserver {
  Poller({required this.task, required this.interval, this.maxBackoff = const Duration(seconds: 60)});

  /// One fetch. Throwing counts as a failure (back-off).
  final Future<void> Function() task;
  final Duration Function() interval;
  final Duration maxBackoff;

  Timer? _timer;
  bool _active = false;
  bool _foreground = true;
  bool _inFlight = false;
  int _failures = 0;

  int get consecutiveFailures => _failures;
  bool get isActive => _active;

  /// Delay before the next tick given the current failure streak.
  Duration get nextDelay => backoffDelay(interval(), _failures, maxBackoff);

  static Duration backoffDelay(Duration base, int failures, Duration cap) {
    if (failures <= 0) return base;
    final ms = base.inMilliseconds * pow(2, min(failures, 10)).toInt();
    return Duration(milliseconds: min(ms, max(cap.inMilliseconds, base.inMilliseconds)));
  }

  void start({bool immediate = true}) {
    if (_active) return;
    _active = true;
    WidgetsBinding.instance.addObserver(this);
    if (immediate) {
      tick();
    } else {
      _schedule();
    }
  }

  void stop() {
    if (!_active) return;
    _active = false;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Fetch now (pull-to-refresh, interval change) and reschedule.
  Future<void> tick() async {
    _timer?.cancel();
    if (_inFlight) return;
    _inFlight = true;
    try {
      await task();
      _failures = 0;
    } catch (_) {
      _failures++;
    } finally {
      _inFlight = false;
    }
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!_active || !_foreground) return;
    _timer = Timer(nextDelay, tick);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_foreground) {
          _foreground = true;
          if (_active) tick();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _foreground = false;
        _timer?.cancel();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }
}
