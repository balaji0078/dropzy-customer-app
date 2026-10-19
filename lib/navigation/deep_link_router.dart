import 'dart:async';

import 'package:flutter/material.dart';

import '../core_api/deep_links.dart';
import '../core_api/payment_coordinator.dart';
import '../screens/v2/payment_flow_screen.dart';
import '../screens/v2/shipment_detail_v2.dart';
import '../screens/v2/surcharge_pay_screen.dart';

/// Maps `dropzy://…` links (SMS, notifications, checkout return) to a
/// `MaterialPageRoute` pushed on the root Navigator (CLIENT_CONTRACTS.md §2.0):
/// `shipments/{id}` → C15, `shipments/{id}/pay` → C11,
/// `payments/return?intentId=` → C10, unknown `dropzy://` → Home.
/// Links that arrive before the home shell is visible (cold start, logged
/// out) are remembered and opened once it is.
class DeepLinkRouter {
  DeepLinkRouter({required this.navigatorKey, required this.payments});
  final GlobalKey<NavigatorState> navigatorKey;
  final PaymentCoordinator payments;

  DeepLink? _pending;
  bool _pendingHome = false;
  bool _ready = false;
  StreamSubscription<Uri>? _sub;
  String? _lastUri;
  DateTime? _lastAt;

  void listen(Stream<Uri> stream) {
    _sub?.cancel();
    _sub = stream.listen(handleUri, onError: (_) {});
  }

  void handleUri(Uri uri) {
    // getInitialLink() and the stream can both deliver the cold-start link.
    final now = DateTime.now();
    if (_lastUri == uri.toString() && _lastAt != null && now.difference(_lastAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastUri = uri.toString();
    _lastAt = now;
    if (uri.scheme.toLowerCase() != 'dropzy') return;
    final link = parseDeepLink(uri);
    if (link != null) {
      open(link);
    } else {
      _home();
    }
  }

  /// Called by the home shell when it mounts / unmounts.
  void setReady(bool ready) {
    _ready = ready;
    if (!ready) return;
    if (_pending != null) {
      final p = _pending!;
      _pending = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => open(p));
    } else if (_pendingHome) {
      _pendingHome = false;
    }
  }

  void _home() {
    final nav = navigatorKey.currentState;
    if (!_ready || nav == null) {
      _pendingHome = true;
      return;
    }
    nav.popUntil((r) => r.isFirst);
  }

  void open(DeepLink link) {
    // An open payment flow takes the checkout return itself.
    if (link is PaymentReturnLink && payments.handleReturn(link.intentId)) return;
    final nav = navigatorKey.currentState;
    if (!_ready || nav == null) {
      _pending = link;
      return;
    }
    switch (link) {
      case ShipmentLink(:final shipmentId):
        nav.push(MaterialPageRoute(builder: (_) => ShipmentDetailV2(shipmentId: shipmentId)));
      case SurchargePayLink(:final shipmentId):
        nav.push(MaterialPageRoute(builder: (_) => SurchargePayScreen(shipmentId: shipmentId)));
      case PaymentReturnLink(:final intentId):
        final id = intentId ?? payments.pending?.intentId;
        if (id == null) return _home();
        nav.push(MaterialPageRoute(builder: (_) => PaymentFlowScreen.verifying(intentId: id)));
    }
  }
}
