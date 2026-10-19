import '../core/api_client.dart';
import '../models/estimate.dart';

/// Rate / pricing estimate. Tries the authenticated /rates/estimate first
/// (matches admin ratesAPI), falling back to /pricing/estimate.
class RatesService {
  RatesService(this._api);
  final ApiClient _api;

  Future<ShippingEstimate> estimate({
    required String pickupPincode,
    required String destinationPincode,
    required String packageType,
    required double weightKg,
    required String mode, // 'domestic' | 'international'
    String? mobile,
    double? shipmentValue,
  }) async {
    final body = {
      'pickup_pincode': pickupPincode,
      'destination_pincode': destinationPincode,
      'destination_city': destinationPincode,
      'package_type': packageType,
      'weight_kg': weightKg,
      'mode': mode,
      if (mobile != null) 'mobile': mobile,
      if (shipmentValue != null) 'shipment_value': shipmentValue,
    };

    try {
      final res = await _api.post('/rates/estimate', body: body);
      return ShippingEstimate.fromJson((unwrap(res) as Map).cast<String, dynamic>());
    } on ApiException catch (e) {
      // Fall back to the public pricing endpoint if rates is unavailable.
      if (e.statusCode == 404 || e.statusCode == 401) {
        final res = await _api.post('/pricing/estimate', body: body, auth: false);
        return ShippingEstimate.fromJson((unwrap(res) as Map).cast<String, dynamic>());
      }
      rethrow;
    }
  }
}
