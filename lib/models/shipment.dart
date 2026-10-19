/// A shipment/booking in Dropzy. Codes look like DCN-DFC-XCG-2026-556147.
class Shipment {
  final String id;
  final String code;
  final String status;
  final String fromCity;
  final String toCity;
  final String? senderName;
  final String? receiverName;
  final double amount;
  final double weightKg;
  final double declaredKg;
  final double actualKg;
  final String? routeText;
  final String? operatorName;
  final DateTime? createdAt;

  Shipment({
    required this.id,
    required this.code,
    required this.status,
    required this.fromCity,
    required this.toCity,
    this.senderName,
    this.receiverName,
    this.amount = 0,
    this.weightKg = 0,
    this.declaredKg = 0,
    this.actualKg = 0,
    this.routeText,
    this.operatorName,
    this.createdAt,
  });

  Shipment copyWith({String? status}) => Shipment(
        id: id,
        code: code,
        status: status ?? this.status,
        fromCity: fromCity,
        toCity: toCity,
        senderName: senderName,
        receiverName: receiverName,
        amount: amount,
        weightKg: weightKg,
        declaredKg: declaredKg,
        actualKg: actualKg,
        routeText: routeText,
        operatorName: operatorName,
        createdAt: createdAt,
      );

  /// True when the driver-verified actual weight exceeds what was declared.
  bool get weightExceeded => declaredKg > 0 && actualKg > declaredKg + 0.001;
  double get extraKg => weightExceeded ? actualKg - declaredKg : 0;

  /// Surcharge for the extra weight (₹40/kg + 18% GST), rounded up.
  double get additionalCharge {
    if (!weightExceeded) return 0;
    final base = extraKg * 40;
    return (base * 1.18).ceilToDouble();
  }

  bool get isWarehouseHold =>
      RegExp(r'warehouse|hold', caseSensitive: false).hasMatch(status);

  /// The extra payment is settled once the backend marks it so.
  bool get additionalPaid => RegExp(
        r'additional_payment_received|payment_received|verified|paid',
        caseSensitive: false,
      ).hasMatch(status);

  factory Shipment.fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => v == null ? 0 : double.tryParse('$v') ?? 0;

    // The API returns route as a single string, e.g. "Chennai → Bangalore".
    final routeStr = (j['route'] as String?)?.trim();
    var from = '${j['from_city'] ?? j['pickup_city'] ?? j['origin'] ?? j['from'] ?? ''}';
    var to = '${j['to_city'] ?? j['destination_city'] ?? j['destination'] ?? j['to'] ?? ''}';
    if ((from.isEmpty || to.isEmpty) && routeStr != null && routeStr.contains('→')) {
      final parts = routeStr.split('→');
      from = parts[0].trim();
      to = parts.length > 1 ? parts[1].trim() : '';
    }

    return Shipment(
      id: '${j['id'] ?? j['_id'] ?? ''}',
      code: '${j['dcn'] ?? j['code'] ?? j['tracking_id'] ?? j['id'] ?? ''}',
      status: '${j['status'] ?? 'booked'}',
      fromCity: from,
      toCity: to,
      senderName: j['sender_name'] ?? j['sender']?['name'],
      receiverName: j['receiver_name'] ?? j['receiver']?['name'],
      amount: d(j['amount'] ?? j['fare'] ?? j['total']),
      weightKg: d(j['actual_kg'] ?? j['declared_kg'] ?? j['weight_kg'] ?? j['weight']),
      declaredKg: d(j['declared_kg'] ?? j['weight_kg'] ?? j['weight']),
      actualKg: d(j['actual_kg'] ?? j['declared_kg'] ?? j['weight_kg'] ?? j['weight']),
      routeText: routeStr,
      operatorName: j['operator'] ?? j['operator_name'],
      createdAt: DateTime.tryParse('${j['created_at'] ?? j['createdAt'] ?? ''}'),
    );
  }

  String get route =>
      (routeText != null && routeText!.isNotEmpty) ? routeText! : '$fromCity → $toCity';

  /// True for statuses shown under the "Active" tab.
  bool get isDelivered => status.toLowerCase().contains('deliver');
  bool get isCancelled =>
      RegExp(r'cancel|fail|return', caseSensitive: false).hasMatch(status);
  bool get isActive => !isDelivered && !isCancelled;
}
