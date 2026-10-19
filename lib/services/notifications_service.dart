import '../core/api_client.dart';
import '../models/notification.dart';

class NotificationsService {
  NotificationsService(this._api);
  final ApiClient _api;

  Future<List<AppNotification>> list({int page = 1, int limit = 20}) async {
    final res = await _api.get('/notifications?page=$page&limit=$limit');
    final data = unwrap(res);
    final List raw = data is List
        ? data
        : (data is Map ? (data['notifications'] ?? data['items'] ?? []) : []);
    return raw
        .whereType<Map>()
        .map((e) => AppNotification.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<int> unreadCount() async {
    try {
      final res = await _api.get('/notifications/unread-count');
      final data = unwrap(res);
      if (data is Map) return int.tryParse('${data['count'] ?? data['unread'] ?? 0}') ?? 0;
      return int.tryParse('$data') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markRead(String id) => _api.patch('/notifications/$id/read');
}
