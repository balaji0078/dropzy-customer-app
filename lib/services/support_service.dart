import '../core/api_client.dart';
import '../models/support_ticket.dart';

class SupportService {
  SupportService(this._api);
  final ApiClient _api;

  Future<List<SupportTicket>> tickets() async {
    final res = await _api.get('/support/tickets');
    final data = unwrap(res);
    final List raw = data is List ? data : const [];
    return raw
        .whereType<Map>()
        .map((e) => SupportTicket.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<void> createTicket(Map<String, dynamic> body) =>
      _api.post('/support/tickets', body: body);
}
