import '../core/api_client.dart';
import '../models/shipment.dart';

/// Shipments — the booking resource the official app uses (POST /shipments).
class ShipmentsService {
  ShipmentsService(this._api);
  final ApiClient _api;

  Future<List<Shipment>> list({int page = 1, int limit = 50}) async {
    final res = await _api.get('/shipments?page=$page&limit=$limit');
    return _extract(res).map(Shipment.fromJson).toList();
  }

  Future<Shipment> getById(String id) async {
    final res = await _api.get('/shipments/$id');
    return Shipment.fromJson((unwrap(res) as Map).cast<String, dynamic>());
  }

  /// Look up a shipment by DCN (or internal id). The list uses the DCN as the
  /// tracking code, so match against the full set.
  Future<Shipment?> trackByDcn(String query) async {
    final q = query.trim().toLowerCase();
    try {
      final direct = await getById(query.trim());
      if (direct.id.isNotEmpty) return direct;
    } catch (_) {/* not an internal id — fall through to DCN match */}
    final all = await list(limit: 200);
    for (final s in all) {
      if (s.code.toLowerCase() == q || s.id.toLowerCase() == q) return s;
    }
    return null;
  }

  Future<Shipment> create(Map<String, dynamic> body) async {
    final res = await _api.post('/shipments', body: body);
    return Shipment.fromJson((unwrap(res) as Map).cast<String, dynamic>());
  }

  /// Advance a shipment to its next lifecycle stage ("Simulate next update").
  Future<Shipment> advance(String id) async {
    final res = await _api.post('/shipments/$id/advance');
    return Shipment.fromJson((unwrap(res) as Map).cast<String, dynamic>());
  }

  /// Pay the additional weight-discrepancy charge. Tries the real endpoint;
  /// callers fall back to a local "paid" state if it isn't available.
  Future<Shipment?> payAdditional(String id, double amount) async {
    for (final ep in ['/shipments/$id/pay-additional', '/shipments/$id/additional-payment']) {
      try {
        final res = await _api.post(ep, body: {'amount': amount, 'method': 'UPI'});
        return Shipment.fromJson((unwrap(res) as Map).cast<String, dynamic>());
      } catch (_) {/* try next */}
    }
    return null;
  }

  /// Fetch the latest state of a shipment (by internal id, falling back to DCN)
  /// — used for live polling of status/timeline.
  Future<Shipment?> refresh(String id, String dcn) async {
    try {
      final s = await getById(id);
      if (s.id.isNotEmpty) return s;
    } catch (_) {/* fall back to DCN lookup */}
    return trackByDcn(dcn.isNotEmpty ? dcn : id);
  }

  List<Map<String, dynamic>> _extract(dynamic res) {
    final data = unwrap(res);
    final List raw = data is List
        ? data
        : (data is Map ? (data['shipments'] ?? data['items'] ?? data['results'] ?? []) : []);
    return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
}
