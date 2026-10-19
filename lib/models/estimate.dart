/// Shipping rate estimate — matches the admin cost-estimator response:
/// { base_price, gst, total_price, estimated_days: { min, max } }
class ShippingEstimate {
  final double basePrice;
  final double gst;
  final double totalPrice;
  final int minDays;
  final int maxDays;
  final String currency;

  ShippingEstimate({
    required this.basePrice,
    required this.gst,
    required this.totalPrice,
    required this.minDays,
    required this.maxDays,
    this.currency = '₹',
  });

  factory ShippingEstimate.fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => v == null ? 0 : double.tryParse('$v') ?? 0;
    int i(dynamic v) => v == null ? 0 : int.tryParse('$v') ?? 0;

    final days = (j['estimated_days'] ?? j['estimatedDays']) as Map?;
    return ShippingEstimate(
      basePrice: d(j['base_price'] ?? j['basePrice']),
      gst: d(j['gst'] ?? j['tax']),
      totalPrice: d(j['total_price'] ?? j['totalPrice'] ?? j['amount']),
      minDays: i(days?['min'] ?? j['min_days']),
      maxDays: i(days?['max'] ?? j['max_days']),
      currency: j['currency'] == 'USD' ? '\$' : '₹',
    );
  }
}
