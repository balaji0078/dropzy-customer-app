import '../core/api_client.dart';
import '../models/tracking.dart';

class TrackingService {
  TrackingService(this._api);
  final ApiClient _api;

  Future<TrackingInfo> forOrder(String orderId) async {
    final res = await _api.get('/tracking/order/$orderId');
    return TrackingInfo.fromJson((unwrap(res) as Map).cast<String, dynamic>());
  }

  Future<TrackingInfo> forParcel(String parcelId) async {
    final res = await _api.get('/parcels/$parcelId/tracking');
    return TrackingInfo.fromJson((unwrap(res) as Map).cast<String, dynamic>());
  }
}
