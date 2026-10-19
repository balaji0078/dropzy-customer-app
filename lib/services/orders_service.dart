import '../core/api_client.dart';
import '../models/order.dart';

class OrdersService {
  OrdersService(this._api);
  final ApiClient _api;

  Future<List<Order>> list({int page = 1, int limit = 20}) async {
    final res = await _api.get('/orders?page=$page&limit=$limit');
    return _extractList(res).map(Order.fromJson).toList();
  }

  Future<Order> getById(String id) async {
    final res = await _api.get('/orders/$id');
    return Order.fromJson((unwrap(res) as Map).cast<String, dynamic>());
  }

  /// Create a booking. The customer flow posts pickup/drop + package details.
  Future<Order> create(Map<String, dynamic> body) async {
    final res = await _api.post('/orders', body: body);
    return Order.fromJson((unwrap(res) as Map).cast<String, dynamic>());
  }

  Future<void> cancel(String id) => _api.patch('/orders/$id/cancel');

  List<Map<String, dynamic>> _extractList(dynamic res) {
    final data = unwrap(res);
    final List raw = data is List
        ? data
        : (data is Map ? (data['orders'] ?? data['items'] ?? data['results'] ?? []) : []);
    return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
}
