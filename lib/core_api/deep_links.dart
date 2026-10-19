/// App deep links (CLIENT_CONTRACTS.md §2.0, §5 `data`):
/// `dropzy://shipments/{id}`, `dropzy://shipments/{id}/pay`,
/// `dropzy://payments/return?intentId={id}`.
sealed class DeepLink {
  const DeepLink();
}

class ShipmentLink extends DeepLink {
  const ShipmentLink(this.shipmentId);
  final String shipmentId;
  @override
  bool operator ==(Object other) => other is ShipmentLink && other.shipmentId == shipmentId;
  @override
  int get hashCode => shipmentId.hashCode;
}

class SurchargePayLink extends DeepLink {
  const SurchargePayLink(this.shipmentId);
  final String shipmentId;
  @override
  bool operator ==(Object other) => other is SurchargePayLink && other.shipmentId == shipmentId;
  @override
  int get hashCode => shipmentId.hashCode ^ 1;
}

class PaymentReturnLink extends DeepLink {
  const PaymentReturnLink(this.intentId);

  /// May be absent: the app then re-checks its pending intent.
  final String? intentId;
  @override
  bool operator ==(Object other) => other is PaymentReturnLink && other.intentId == intentId;
  @override
  int get hashCode => intentId.hashCode ^ 2;
}

DeepLink? parseDeepLink(Uri uri) {
  if (uri.scheme.toLowerCase() != 'dropzy') return null;
  final segs = <String>[
    if (uri.host.isNotEmpty) uri.host.toLowerCase(),
    ...uri.pathSegments.where((s) => s.isNotEmpty),
  ];
  if (segs.length >= 2 && segs[0] == 'shipments') {
    if (segs.length == 2) return ShipmentLink(segs[1]);
    if (segs.length == 3 && segs[2] == 'pay') return SurchargePayLink(segs[1]);
    return null;
  }
  if (segs.length == 2 && segs[0] == 'payments' && segs[1] == 'return') {
    final id = uri.queryParameters['intentId'];
    return PaymentReturnLink(id == null || id.isEmpty ? null : id);
  }
  return null;
}

/// Notification `data` → link: `{"screen":"surchargePay","shipmentId":…}` →
/// C11, `{"screen":"shipment",…}` → C15.
DeepLink? deepLinkFromNotification(Map<String, dynamic> data, {String? fallbackShipmentId}) {
  final id = '${data['shipmentId'] ?? fallbackShipmentId ?? ''}';
  if (id.isEmpty) return null;
  switch ('${data['screen'] ?? ''}') {
    case 'surchargePay':
      return SurchargePayLink(id);
    case 'shipment':
      return ShipmentLink(id);
  }
  return fallbackShipmentId != null ? ShipmentLink(id) : null;
}
