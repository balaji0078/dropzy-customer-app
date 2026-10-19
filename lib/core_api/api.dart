import '../core/api_client.dart';
import '../core/constants.dart';
import 'models.dart';

/// Typed wrapper over the core endpoints the customer app may call
/// (CLIENT_CONTRACTS.md §2.1). Every mutating command takes the caller's
/// [idempotencyKey] — created when the user action is created, reused for
/// retries of that action (§1.4). `/auth/*` is exempt.
class CoreApi {
  CoreApi(this.client);
  final ApiClient client;

  // ─── Auth (C2/C3) ───

  Future<OtpChallenge> requestOtp(String phone) async {
    final r = await client.send('POST', '/auth/otp/request', auth: false, body: {'phone': phone});
    return OtpChallenge.fromJson(r.dataMap);
  }

  Future<AuthResult> verifyOtp({
    required String challengeId,
    required String phone,
    required String code,
    String? deviceId,
    String? platform,
    String? deviceName,
  }) async {
    final r = await client.send('POST', '/auth/otp/verify', auth: false, body: {
      'challengeId': challengeId,
      'phone': phone,
      'code': code,
      'appVariant': 'customer',
      'device': {
        if (deviceId != null) 'deviceId': deviceId,
        if (platform != null) 'platform': platform,
        if (deviceName != null) 'name': deviceName,
      },
    });
    return AuthResult.fromJson(r.dataMap);
  }

  Future<void> logout() => client.send('POST', '/auth/logout');

  // ─── Me (C1/C19) ───

  Future<Me> me() async => Me.fromJson((await client.send('GET', '/me')).dataMap);

  Future<Me> updateMe({String? name, required String idempotencyKey}) async {
    final r = await client.send('PATCH', '/me',
        body: {if (name != null) 'name': name}, idempotencyKey: idempotencyKey);
    return Me.fromJson(r.dataMap);
  }

  Future<List<SessionInfo>> sessions() async =>
      (await client.send('GET', '/me/sessions')).dataList.map(SessionInfo.fromJson).toList();

  Future<void> revokeSession(String id, {required String idempotencyKey}) =>
      client.send('DELETE', '/me/sessions/$id', idempotencyKey: idempotencyKey);

  // ─── Notifications (C4/C17) ───

  Future<Paged<CoreNotification>> notifications({int page = 1, int limit = 20}) async {
    final r = await client.send('GET', '/me/notifications', query: {'page': '$page', 'limit': '$limit'});
    return Paged(r.dataList.map(CoreNotification.fromJson).toList(), PageMeta.fromJson(r.meta));
  }

  Future<int> unreadCount() async {
    final r = await client.send('GET', '/me/notifications/unread-count');
    final v = r.dataMap['unread'];
    return v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
  }

  Future<void> markNotificationRead(String id, {required String idempotencyKey}) =>
      client.send('POST', '/me/notifications/$id/read', idempotencyKey: idempotencyKey);

  Future<void> markAllNotificationsRead({required String idempotencyKey}) =>
      client.send('POST', '/me/notifications/read-all', idempotencyKey: idempotencyKey);

  // ─── Catalog (C5/C6) ───

  Future<List<StopRef>> stops({required String role, String? originStopId}) async {
    final r = await client.send('GET', '/catalog/stops',
        query: {'role': role, if (originStopId != null) 'originStopId': originStopId});
    return r.dataList.map(StopRef.fromJson).toList();
  }

  Future<List<TripOffer>> trips({required String originStopId, required String destinationStopId, required String date}) async {
    final r = await client.send('GET', '/catalog/trips',
        query: {'originStopId': originStopId, 'destinationStopId': destinationStopId, 'date': date});
    return r.dataList.map(TripOffer.fromJson).toList();
  }

  Future<ParcelPolicy> parcelPolicy() async =>
      ParcelPolicy.fromJson((await client.send('GET', '/catalog/parcel-categories')).dataMap);

  // ─── Bookings (C7/C8/C16) ───

  Future<BookingQuote> quote(Map<String, dynamic> request, {required String idempotencyKey}) async {
    final r = await client.send('POST', '/bookings/quote', body: request, idempotencyKey: idempotencyKey);
    return BookingQuote.fromJson(r.dataMap);
  }

  Future<BookingCreated> createBooking(Map<String, dynamic> request, {required String idempotencyKey}) async {
    final r = await client.send('POST', '/bookings', body: request, idempotencyKey: idempotencyKey);
    return BookingCreated.fromJson(r.dataMap);
  }

  Future<Booking> cancelBooking(String bookingId, String reason, {required String idempotencyKey}) async {
    final r = await client.send('POST', '/bookings/$bookingId/cancel',
        body: {'reason': reason}, idempotencyKey: idempotencyKey);
    return Booking.fromJson(r.dataMap);
  }

  // ─── Shipments (C4/C12/C14/C15) ───

  Future<Paged<ShipmentSummary>> shipments({String view = 'all', int page = 1, int limit = 20}) async {
    final r = await client.send('GET', '/shipments', query: {'view': view, 'page': '$page', 'limit': '$limit'});
    return Paged(r.dataList.map(ShipmentSummary.fromJson).toList(), PageMeta.fromJson(r.meta));
  }

  Future<ShipmentView> shipment(String id) async =>
      ShipmentView.fromJson((await client.send('GET', '/shipments/$id')).dataMap);

  Future<ShipmentView> shipmentByDcn(String dcn) async =>
      ShipmentView.fromJson((await client.send('GET', '/shipments/by-dcn/${Uri.encodeComponent(dcn)}')).dataMap);

  Future<List<TimelineEntry>> timeline(String id) async =>
      (await client.send('GET', '/shipments/$id/timeline')).dataList.map(TimelineEntry.fromJson).toList();

  Future<SurchargeStatus> currentSurcharge(String shipmentId) async =>
      SurchargeStatus.fromJson((await client.send('GET', '/shipments/$shipmentId/surcharge-quotes/current')).dataMap);

  Future<SurchargeQuote> acknowledgeSurcharge(String shipmentId, String quoteId, {required String idempotencyKey}) async {
    final r = await client.send('POST', '/shipments/$shipmentId/surcharge-quotes/$quoteId/accept',
        idempotencyKey: idempotencyKey);
    return SurchargeQuote.fromJson(r.dataMap);
  }

  // ─── Payments (C8–C11) ───

  Future<PaymentIntent> createPaymentIntent(String invoiceId, {required String idempotencyKey}) async {
    final r = await client.send('POST', '/payments/intents',
        body: {'invoiceId': invoiceId, 'returnUrl': AppConfig.paymentReturnUrl}, idempotencyKey: idempotencyKey);
    return PaymentIntent.fromJson(r.dataMap);
  }

  Future<PaymentIntent> paymentIntent(String id) async =>
      PaymentIntent.fromJson((await client.send('GET', '/payments/intents/$id')).dataMap);

  Future<PaymentIntent> refreshPaymentIntent(String id, {required String idempotencyKey}) async {
    final r = await client.send('POST', '/payments/intents/$id/refresh', idempotencyKey: idempotencyKey);
    return PaymentIntent.fromJson(r.dataMap);
  }

  // ─── Disputes (C13) ───

  Future<Dispute> openDispute(
    String shipmentId, {
    required String quoteId,
    required String reasonCode,
    required String description,
    List<String> evidenceIds = const [],
    required String idempotencyKey,
  }) async {
    final r = await client.send('POST', '/shipments/$shipmentId/disputes',
        body: {
          'quoteId': quoteId,
          'reasonCode': reasonCode,
          'description': description,
          if (evidenceIds.isNotEmpty) 'evidenceIds': evidenceIds,
        },
        idempotencyKey: idempotencyKey);
    return Dispute.fromJson(r.dataMap);
  }

  // ─── Support (C18) ───

  Future<Paged<Ticket>> tickets({int page = 1, int limit = 20}) async {
    final r = await client.send('GET', '/support/tickets', query: {'page': '$page', 'limit': '$limit'});
    return Paged(r.dataList.map(Ticket.fromJson).toList(), PageMeta.fromJson(r.meta));
  }

  Future<Ticket> createTicket({
    required String category,
    required String subject,
    required String message,
    String? shipmentId,
    required String idempotencyKey,
  }) async {
    final r = await client.send('POST', '/support/tickets',
        body: {
          'category': category,
          'subject': subject,
          'message': message,
          if (shipmentId != null) 'shipmentId': shipmentId,
        },
        idempotencyKey: idempotencyKey);
    return Ticket.fromJson(r.dataMap);
  }

  Future<TicketDetail> ticket(String id) async =>
      TicketDetail.fromJson((await client.send('GET', '/support/tickets/$id')).dataMap);

  Future<TicketMessage> addTicketMessage(String id, String body, {required String idempotencyKey}) async {
    final r = await client.send('POST', '/support/tickets/$id/messages',
        body: {'body': body}, idempotencyKey: idempotencyKey);
    return TicketMessage.fromJson(r.dataMap);
  }

  // ─── Evidence (C6 parcel photo, C13 dispute photos) ───

  Future<Evidence> uploadEvidence({
    required List<int> bytes,
    required String filename,
    required String kind,
    String? shipmentId,
    String contentType = 'image/jpeg',
    DateTime? capturedAt,
    required String idempotencyKey,
  }) async {
    final r = await client.upload('/evidence',
        bytes: bytes,
        filename: filename,
        contentType: contentType,
        fields: {
          'kind': kind,
          if (shipmentId != null) 'shipmentId': shipmentId,
          if (capturedAt != null) 'capturedAtDevice': capturedAt.toUtc().toIso8601String(),
        },
        idempotencyKey: idempotencyKey);
    return Evidence.fromJson(r.dataMap);
  }

  Future<Evidence> evidence(String id) async =>
      Evidence.fromJson((await client.send('GET', '/evidence/$id')).dataMap);
}
