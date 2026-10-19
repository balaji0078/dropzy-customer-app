/// Which invoice a payment flow is settling.
enum PaymentPurpose { baseFare, surcharge }

/// The intent the user is currently paying in the hosted checkout.
class PendingPayment {
  const PendingPayment({required this.intentId, required this.purpose, this.shipmentId});
  final String intentId;
  final PaymentPurpose purpose;
  final String? shipmentId;
}

/// Connects the `dropzy://payments/return` deep link (and the app-resume
/// fallback) to the open payment flow. Never changes payment state itself —
/// it only tells the flow to go and ask the server (STATE_MACHINE.md §6.3:
/// the redirect is never proof of payment).
class PaymentCoordinator {
  PendingPayment? pending;
  bool Function(String? intentId)? _handler;

  /// Called by the open payment flow screen.
  void attach(bool Function(String? intentId) handler) => _handler = handler;

  void detach(bool Function(String? intentId) handler) {
    if (identical(_handler, handler)) _handler = null;
  }

  bool get hasActiveFlow => _handler != null;

  /// Returns true when an open flow consumed the return.
  bool handleReturn(String? intentId) => _handler?.call(intentId) ?? false;
}
