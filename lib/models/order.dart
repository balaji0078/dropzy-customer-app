/// A booking / order in Dropzy. Fields are defensive because the Go
/// backend returns slightly different shapes across endpoints.
class Order {
  final String id;
  final String code; // human-friendly tracking id
  final String status;
  final String? pickupAddress;
  final String? dropAddress;
  final String? pickupPincode;
  final String? dropPincode;
  final String packageType;
  final double weightKg;
  final double amount;
  final String currency;
  final DateTime? createdAt;

  Order({
    required this.id,
    required this.code,
    required this.status,
    this.pickupAddress,
    this.dropAddress,
    this.pickupPincode,
    this.dropPincode,
    this.packageType = 'PARCEL',
    this.weightKg = 0,
    this.amount = 0,
    this.currency = '₹',
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => v == null ? 0 : double.tryParse('$v') ?? 0;
    DateTime? dt(dynamic v) => v == null ? null : DateTime.tryParse('$v');

    return Order(
      id: '${j['id'] ?? j['_id'] ?? ''}',
      code: '${j['order_code'] ?? j['tracking_id'] ?? j['code'] ?? j['id'] ?? ''}',
      status: '${j['status'] ?? 'pending'}',
      pickupAddress: j['pickup_address'] ?? j['pickupAddress'] ?? j['origin'],
      dropAddress: j['drop_address'] ?? j['dropAddress'] ?? j['destination'],
      pickupPincode: (j['pickup_pincode'] ?? j['pickupPincode'])?.toString(),
      dropPincode: (j['drop_pincode'] ?? j['destination_pincode'])?.toString(),
      packageType: '${j['package_type'] ?? j['packageType'] ?? 'PARCEL'}',
      weightKg: d(j['weight_kg'] ?? j['weight']),
      amount: d(j['amount'] ?? j['total_price'] ?? j['total']),
      currency: j['currency'] == 'USD' ? '\$' : '₹',
      createdAt: dt(j['created_at'] ?? j['createdAt']),
    );
  }
}
