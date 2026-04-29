class Parcel {
  final String id;
  final String trackingId;
  final String senderName;
  final String senderPhone;
  final String senderCity;
  final String receiverName;
  final String receiverPhone;
  final String receiverCity;
  final String packageType;
  final double weight;
  final String status;
  final DateTime estimatedDelivery;
  final double price;
  final DateTime createdAt;
  final String route;
  final String? eWayBillNo;

  Parcel({
    required this.id,
    required this.trackingId,
    required this.senderName,
    required this.senderPhone,
    required this.senderCity,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverCity,
    required this.packageType,
    required this.weight,
    required this.status,
    required this.estimatedDelivery,
    required this.price,
    required this.createdAt,
    required this.route,
    this.eWayBillNo,
  });

  /// Parse from backend API response (snake_case keys) or legacy camelCase
  factory Parcel.fromJson(Map<String, dynamic> json) {
    // Handle API wrapper: response may have { data: { ... } }
    final d = json.containsKey('data') && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final pickupAddr = d['pickup_address'] as String? ?? '';
    final deliveryAddr = d['delivery_address'] as String? ?? '';

    return Parcel(
      id: (d['id'] ?? d['ID'] ?? '').toString(),
      trackingId: (d['tracking_id'] ?? d['trackingId'] ?? d['id'] ?? '').toString(),
      senderName: (d['sender_name'] ?? d['senderName'] ?? 'You').toString(),
      senderPhone: (d['sender_phone'] ?? d['senderPhone'] ?? '').toString(),
      senderCity: (d['sender_city'] ?? d['senderCity'] ?? _cityFromAddress(pickupAddr)).toString(),
      receiverName: (d['receiver_name'] ?? d['receiverName'] ?? '').toString(),
      receiverPhone: (d['receiver_phone'] ?? d['receiverPhone'] ?? '').toString(),
      receiverCity: (d['receiver_city'] ?? d['receiverCity'] ?? _cityFromAddress(deliveryAddr)).toString(),
      packageType: (d['package_type'] ?? d['packageType'] ?? '').toString(),
      weight: ((d['package_weight'] ?? d['weight']) as num?)?.toDouble() ?? 0.0,
      status: _normalizeStatus((d['status'] ?? 'pending').toString()),
      estimatedDelivery: _parseDate(d['estimated_delivery_time'] ?? d['estimatedDelivery']),
      price: ((d['total_amount'] ?? d['price']) as num?)?.toDouble() ?? 0.0,
      createdAt: _parseDate(d['created_at'] ?? d['createdAt']),
      route: d['route']?.toString() ?? '${_cityFromAddress(pickupAddr)} → ${_cityFromAddress(deliveryAddr)}',
      eWayBillNo: d['e_way_bill_no']?.toString() ?? d['eWayBillNo']?.toString(),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static String _cityFromAddress(String address) {
    if (address.isEmpty) return '';
    // Try to extract city name from address like "123 Anna Nagar, Chennai 600040"
    final parts = address.split(',');
    if (parts.length >= 2) {
      return parts[parts.length - 1].trim().replaceAll(RegExp(r'\d+'), '').trim();
    }
    return address.length > 20 ? '${address.substring(0, 20)}...' : address;
  }

  static String _normalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Picked Up';
      case 'picked_up': return 'Picked Up';
      case 'in_transit': return 'In Transit';
      case 'out_for_delivery': return 'Out for Delivery';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackingId': trackingId,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'senderCity': senderCity,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'receiverCity': receiverCity,
      'packageType': packageType,
      'weight': weight,
      'status': status,
      'estimatedDelivery': estimatedDelivery.toIso8601String(),
      'price': price,
      'createdAt': createdAt.toIso8601String(),
      'route': route,
      'eWayBillNo': eWayBillNo,
    };
  }

  Parcel copyWith({
    String? id,
    String? trackingId,
    String? senderName,
    String? senderPhone,
    String? senderCity,
    String? receiverName,
    String? receiverPhone,
    String? receiverCity,
    String? packageType,
    double? weight,
    String? status,
    DateTime? estimatedDelivery,
    double? price,
    DateTime? createdAt,
    String? route,
    String? eWayBillNo,
  }) {
    return Parcel(
      id: id ?? this.id,
      trackingId: trackingId ?? this.trackingId,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      senderCity: senderCity ?? this.senderCity,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      receiverCity: receiverCity ?? this.receiverCity,
      packageType: packageType ?? this.packageType,
      weight: weight ?? this.weight,
      status: status ?? this.status,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      route: route ?? this.route,
      eWayBillNo: eWayBillNo ?? this.eWayBillNo,
    );
  }
}
