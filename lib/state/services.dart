import '../core/api_client.dart';
import '../services/auth_service.dart';
import '../services/rates_service.dart';
import '../services/orders_service.dart';
import '../services/shipments_service.dart';
import '../services/tracking_service.dart';
import '../services/notifications_service.dart';
import '../services/support_service.dart';

/// Single container wiring every service to one shared ApiClient.
class Services {
  Services() : api = ApiClient() {
    auth = AuthService(api);
    rates = RatesService(api);
    orders = OrdersService(api);
    shipments = ShipmentsService(api);
    tracking = TrackingService(api);
    notifications = NotificationsService(api);
    support = SupportService(api);
  }

  final ApiClient api;
  late final AuthService auth;
  late final RatesService rates;
  late final OrdersService orders;
  late final ShipmentsService shipments;
  late final TrackingService tracking;
  late final NotificationsService notifications;
  late final SupportService support;
}
