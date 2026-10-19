/// Core API (PRD v2.0, openapi.yaml) models used by the customer app.
/// Parsing is defensive: missing fields become null/empty, never throw.
library;

int? _i(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}'));
String? _s(dynamic v) => v == null ? null : '$v';
String _sv(dynamic v, [String fallback = '']) => v == null ? fallback : '$v';
DateTime? _t(dynamic v) => v == null ? null : DateTime.tryParse('$v');
bool _b(dynamic v) => v == true;
Map<String, dynamic>? _m(dynamic v) => v is Map ? v.cast<String, dynamic>() : null;
List<Map<String, dynamic>> _l(dynamic v) =>
    v is List ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() : const [];
List<String> _sl(dynamic v) => v is List ? v.map((e) => '$e').toList() : const [];

class PageMeta {
  const PageMeta({this.page = 1, this.limit = 20, this.total = 0, this.totalPages = 1});
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  bool get hasMore => page < totalPages;

  factory PageMeta.fromJson(Map<String, dynamic> j) => PageMeta(
        page: _i(j['page']) ?? 1,
        limit: _i(j['limit']) ?? 20,
        total: _i(j['total']) ?? 0,
        totalPages: _i(j['totalPages']) ?? 1,
      );
}

class Paged<T> {
  const Paged(this.items, this.meta);
  final List<T> items;
  final PageMeta meta;
}

// ─── Auth / me ───

class Me {
  Me({required this.id, required this.phone, this.name, this.email, this.status, this.roles = const []});
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String? status;
  final List<String> roles;

  String get displayName => (name ?? '').trim().isEmpty ? 'Customer' : name!.trim();
  String get firstName => displayName.split(' ').first;

  factory Me.fromJson(Map<String, dynamic> j) => Me(
        id: _sv(j['id']),
        phone: _sv(j['phone']),
        name: _s(j['name']),
        email: _s(j['email']),
        status: _s(j['status']),
        roles: _l(j['roles']).map((r) => _sv(r['role'])).toList(),
      );
}

class SessionInfo {
  SessionInfo({required this.id, this.appVariant, this.deviceName, this.devicePlatform, this.createdAt, this.lastUsedAt, this.current = false});
  final String id;
  final String? appVariant;
  final String? deviceName;
  final String? devicePlatform;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;
  final bool current;

  factory SessionInfo.fromJson(Map<String, dynamic> j) => SessionInfo(
        id: _sv(j['id']),
        appVariant: _s(j['appVariant']),
        deviceName: _s(j['deviceName']),
        devicePlatform: _s(j['devicePlatform']),
        createdAt: _t(j['createdAt']),
        lastUsedAt: _t(j['lastUsedAt']),
        current: _b(j['current']),
      );
}

class OtpChallenge {
  OtpChallenge({required this.challengeId, this.phoneMasked, this.expiresAt, this.resendAfterSeconds = 30, this.codeLength = 6, this.devCode});
  final String challengeId;
  final String? phoneMasked;
  final DateTime? expiresAt;
  final int resendAfterSeconds;

  /// Number of OTP boxes to render. Default 6 when absent (dev backend: 4).
  final int codeLength;
  final String? devCode;

  factory OtpChallenge.fromJson(Map<String, dynamic> j) {
    final len = _i(j['codeLength']);
    return OtpChallenge(
      challengeId: _sv(j['challengeId']),
      phoneMasked: _s(j['phoneMasked']),
      expiresAt: _t(j['expiresAt']),
      resendAfterSeconds: _i(j['resendAfterSeconds']) ?? 30,
      codeLength: (len == null || len < 4 || len > 8) ? 6 : len,
      devCode: _s(j['devCode']),
    );
  }
}

class AuthResult {
  AuthResult({this.mfaRequired = false, this.accessToken, this.refreshToken, this.isNewUser = false, this.user, this.codeLength});
  final bool mfaRequired;
  final String? accessToken;
  final String? refreshToken;
  final bool isNewUser;
  final Me? user;
  final int? codeLength;

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        mfaRequired: _b(j['mfaRequired']),
        accessToken: _s(j['accessToken']),
        refreshToken: _s(j['refreshToken']),
        isNewUser: _b(j['isNewUser']),
        user: _m(j['user']) == null ? null : Me.fromJson(_m(j['user'])!),
        codeLength: _i(j['codeLength']),
      );
}

// ─── Catalog ───

class StopRef {
  StopRef({required this.id, this.code, required this.name, this.cityName, this.address});
  final String id;
  final String? code;
  final String name;
  final String? cityName;
  final String? address;

  String get title => (cityName != null && cityName!.isNotEmpty && !name.contains(cityName!)) ? '$cityName — $name' : name;
  String get shortName => (cityName != null && cityName!.isNotEmpty) ? cityName! : name;

  factory StopRef.fromJson(Map<String, dynamic> j) => StopRef(
        id: _sv(j['id']),
        code: _s(j['code']),
        name: _sv(j['name'], _sv(j['code'])),
        cityName: _s(j['cityName']),
        address: _s(j['address']),
      );

  static StopRef? maybe(dynamic v) => _m(v) == null ? null : StopRef.fromJson(_m(v)!);
}

class Warehouse {
  Warehouse({this.id, required this.name, this.address, this.openingHours, this.phone, this.latitude, this.longitude});
  final String? id;
  final String name;
  final String? address;
  final String? openingHours;
  final String? phone;
  final String? latitude;
  final String? longitude;

  factory Warehouse.fromJson(Map<String, dynamic> j) => Warehouse(
        id: _s(j['id']),
        name: _sv(j['name'], 'the destination warehouse'),
        address: _s(j['address']),
        openingHours: _s(j['openingHours']),
        phone: _s(j['phone']),
        latitude: _s(j['latitude']),
        longitude: _s(j['longitude']),
      );

  static Warehouse? maybe(dynamic v) => _m(v) == null ? null : Warehouse.fromJson(_m(v)!);
}

class TripOffer {
  TripOffer({required this.tripId, this.routeName, this.operatorName, this.vehicleReg, this.departureAtOrigin, this.arrivalAtDestination, this.bookingClosesAt, this.bookable = false, this.destinationWarehouse});
  final String tripId;
  final String? routeName;
  final String? operatorName;
  final String? vehicleReg;
  final DateTime? departureAtOrigin;
  final DateTime? arrivalAtDestination;
  final DateTime? bookingClosesAt;
  final bool bookable;
  final Warehouse? destinationWarehouse;

  factory TripOffer.fromJson(Map<String, dynamic> j) => TripOffer(
        tripId: _sv(j['tripId']),
        routeName: _s(j['routeName']),
        operatorName: _s(j['operatorName']),
        vehicleReg: _s(j['vehicleReg']),
        departureAtOrigin: _t(j['departureAtOrigin']),
        arrivalAtDestination: _t(j['arrivalAtDestination']),
        bookingClosesAt: _t(j['bookingClosesAt']),
        bookable: _b(j['bookable']),
        destinationWarehouse: Warehouse.maybe(j['destinationWarehouse']),
      );
}

class PolicyTexts {
  const PolicyTexts({this.weightPolicy, this.restrictedItems, this.cancellation});
  final String? weightPolicy;
  final String? restrictedItems;
  final String? cancellation;

  factory PolicyTexts.fromJson(Map<String, dynamic>? j) => PolicyTexts(
        weightPolicy: _s(j?['weightPolicy']),
        restrictedItems: _s(j?['restrictedItems']),
        cancellation: _s(j?['cancellation']),
      );
}

class ParcelPolicy {
  ParcelPolicy({
    this.categories = const [],
    this.allowedInputUnits = const ['g', 'kg'],
    this.minDeclaredGrams,
    this.maxDeclaredGrams,
    this.maxDimensionCm,
    this.toleranceGrams,
    this.serviceOptions = const ['STOP_HANDOVER'],
    this.texts = const PolicyTexts(),
  });
  final List<String> categories;
  final List<String> allowedInputUnits;
  final int? minDeclaredGrams;
  final int? maxDeclaredGrams;
  final int? maxDimensionCm;
  final int? toleranceGrams;
  final List<String> serviceOptions;
  final PolicyTexts texts;

  factory ParcelPolicy.fromJson(Map<String, dynamic> j) {
    final units = _sl(j['allowedInputUnits']);
    final opts = _sl(j['serviceOptions']);
    return ParcelPolicy(
      categories: _sl(j['categories']),
      allowedInputUnits: units.isEmpty ? const ['g', 'kg'] : units,
      minDeclaredGrams: _i(j['minDeclaredGrams']),
      maxDeclaredGrams: _i(j['maxDeclaredGrams']),
      maxDimensionCm: _i(j['maxDimensionCm']),
      toleranceGrams: _i(j['toleranceGrams']),
      serviceOptions: opts.isEmpty ? const ['STOP_HANDOVER'] : opts,
      texts: PolicyTexts.fromJson(_m(j['texts'])),
    );
  }
}

// ─── Money ───

class BreakdownLine {
  BreakdownLine({required this.code, required this.label, required this.amountPaise});
  final String code;
  final String label;
  final int amountPaise;

  factory BreakdownLine.fromJson(Map<String, dynamic> j) => BreakdownLine(
        code: _sv(j['code'] ?? j['lineType']),
        label: _sv(j['label'] ?? j['description']),
        amountPaise: _i(j['amountPaise']) ?? 0,
      );
}

class FareBreakdown {
  FareBreakdown({this.lines = const [], this.totalPaise = 0, this.taxPaise, this.totalDisplay});
  final List<BreakdownLine> lines;
  final int totalPaise;
  final int? taxPaise;
  final String? totalDisplay;

  factory FareBreakdown.fromJson(Map<String, dynamic>? j) => FareBreakdown(
        lines: _l(j?['lines']).map(BreakdownLine.fromJson).toList(),
        totalPaise: _i(j?['totalPaise']) ?? 0,
        taxPaise: _i(j?['taxPaise']),
        totalDisplay: _s(j?['totalDisplay']),
      );
}

class BookingQuote {
  BookingQuote({
    required this.quoteId,
    this.expiresAt,
    this.origin,
    this.destination,
    this.departureAtOrigin,
    this.arrivalAtDestination,
    this.paymentCutoffAt,
    this.declaredWeightGrams,
    this.declaredWeightDisplay,
    required this.fare,
    this.policy,
  });
  final String quoteId;
  final DateTime? expiresAt;
  final StopRef? origin;
  final StopRef? destination;
  final DateTime? departureAtOrigin;
  final DateTime? arrivalAtDestination;
  final DateTime? paymentCutoffAt;
  final int? declaredWeightGrams;
  final String? declaredWeightDisplay;
  final FareBreakdown fare;
  final ParcelPolicy? policy;

  factory BookingQuote.fromJson(Map<String, dynamic> j) => BookingQuote(
        quoteId: _sv(j['quoteId']),
        expiresAt: _t(j['expiresAt']),
        origin: StopRef.maybe(j['origin']),
        destination: StopRef.maybe(j['destination']),
        departureAtOrigin: _t(j['departureAtOrigin']),
        arrivalAtDestination: _t(j['arrivalAtDestination']),
        paymentCutoffAt: _t(j['paymentCutoffAt']),
        declaredWeightGrams: _i(j['declaredWeightGrams']),
        declaredWeightDisplay: _s(j['declaredWeightDisplay']),
        fare: FareBreakdown.fromJson(_m(j['fare'])),
        policy: _m(j['policy']) == null ? null : ParcelPolicy.fromJson(_m(j['policy'])!),
      );
}

class PaymentIntent {
  PaymentIntent({
    required this.id,
    required this.invoiceId,
    this.invoiceKind,
    this.shipmentId,
    required this.status,
    this.amountPaise = 0,
    this.checkoutPath,
    this.expiresAt,
    this.lastSyncedAt,
    this.failureMessage,
    this.isOrphan = false,
  });
  final String id;
  final String invoiceId;
  final String? invoiceKind;
  final String? shipmentId;
  final String status;
  final int amountPaise;
  final String? checkoutPath;
  final DateTime? expiresAt;
  final DateTime? lastSyncedAt;
  final String? failureMessage;
  final bool isOrphan;

  factory PaymentIntent.fromJson(Map<String, dynamic> j) => PaymentIntent(
        id: _sv(j['id']),
        invoiceId: _sv(j['invoiceId']),
        invoiceKind: _s(j['invoiceKind']),
        shipmentId: _s(j['shipmentId']),
        status: _sv(j['status'], 'CREATED'),
        amountPaise: _i(j['amountPaise']) ?? 0,
        checkoutPath: _s(j['checkoutPath']),
        expiresAt: _t(j['expiresAt']),
        lastSyncedAt: _t(j['lastSyncedAt']),
        failureMessage: _s(j['failureMessage']),
        isOrphan: _b(j['isOrphan']),
      );

  static PaymentIntent? maybe(dynamic v) => _m(v) == null ? null : PaymentIntent.fromJson(_m(v)!);
}

class Invoice {
  Invoice({required this.id, this.invoiceNumber, this.kind, required this.status, this.totalPaise = 0, this.dueAt, this.paidAt, this.activeIntent});
  final String id;
  final String? invoiceNumber;
  final String? kind;
  final String status;
  final int totalPaise;
  final DateTime? dueAt;
  final DateTime? paidAt;
  final PaymentIntent? activeIntent;

  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
        id: _sv(j['id']),
        invoiceNumber: _s(j['invoiceNumber']),
        kind: _s(j['kind']),
        status: _sv(j['status'], 'OPEN'),
        totalPaise: _i(j['totalPaise']) ?? 0,
        dueAt: _t(j['dueAt']),
        paidAt: _t(j['paidAt']),
        activeIntent: PaymentIntent.maybe(j['activeIntent']),
      );

  static Invoice? maybe(dynamic v) => _m(v) == null ? null : Invoice.fromJson(_m(v)!);
}

class Booking {
  Booking({required this.id, this.shipmentId, this.status, this.refundPaise, this.baseTotalPaise});
  final String id;
  final String? shipmentId;
  final String? status;
  final int? refundPaise;
  final int? baseTotalPaise;

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: _sv(j['id']),
        shipmentId: _s(j['shipmentId']),
        status: _s(j['status']),
        refundPaise: _i(j['refundPaise']),
        baseTotalPaise: _i(j['baseTotalPaise']),
      );
}

class BookingCreated {
  BookingCreated({required this.booking, required this.shipment, required this.invoice, this.paymentExpiresAt});
  final Booking booking;
  final ShipmentSummary shipment;
  final Invoice invoice;
  final DateTime? paymentExpiresAt;

  factory BookingCreated.fromJson(Map<String, dynamic> j) => BookingCreated(
        booking: Booking.fromJson(_m(j['booking']) ?? const {}),
        shipment: ShipmentSummary.fromJson(_m(j['shipment']) ?? const {}),
        invoice: Invoice.fromJson(_m(j['invoice']) ?? const {}),
        paymentExpiresAt: _t(j['paymentExpiresAt']),
      );
}

// ─── Shipments ───

class ShipmentSummary {
  ShipmentSummary({
    required this.id,
    this.dcn,
    this.bookingId,
    required this.state,
    this.stateLabel,
    this.origin,
    this.destination,
    this.plannedDepartureAt,
    this.plannedArrivalAt,
    this.cutoffAt,
    this.declaredWeightGrams,
    this.amountDuePaise = 0,
    this.surchargeDue = false,
    this.warehouseRequired = false,
    this.createdAt,
  });
  final String id;
  final String? dcn;
  final String? bookingId;
  final String state;
  final String? stateLabel;
  final StopRef? origin;
  final StopRef? destination;
  final DateTime? plannedDepartureAt;
  final DateTime? plannedArrivalAt;
  final DateTime? cutoffAt;
  final int? declaredWeightGrams;
  final int amountDuePaise;
  final bool surchargeDue;
  final bool warehouseRequired;
  final DateTime? createdAt;

  String get routeText => '${origin?.shortName ?? '—'} → ${destination?.shortName ?? '—'}';

  factory ShipmentSummary.fromJson(Map<String, dynamic> j) => ShipmentSummary(
        id: _sv(j['id']),
        dcn: _s(j['dcn']),
        bookingId: _s(j['bookingId']),
        state: _sv(j['state']),
        stateLabel: _s(j['stateLabel']),
        origin: StopRef.maybe(j['origin']),
        destination: StopRef.maybe(j['destination']),
        plannedDepartureAt: _t(j['plannedDepartureAt']),
        plannedArrivalAt: _t(j['plannedArrivalAt']),
        cutoffAt: _t(j['cutoffAt']),
        declaredWeightGrams: _i(j['declaredWeightGrams']),
        amountDuePaise: _i(j['amountDuePaise']) ?? 0,
        surchargeDue: _b(j['surchargeDue']),
        warehouseRequired: _b(j['warehouseRequired']),
        createdAt: _t(j['createdAt']),
      );
}

class PartyView {
  PartyView({this.name, this.phone, this.phoneMasked = false});
  final String? name;
  final String? phone;
  final bool phoneMasked;

  factory PartyView.fromJson(Map<String, dynamic> j) =>
      PartyView(name: _s(j['name']), phone: _s(j['phone']), phoneMasked: _b(j['phoneMasked']));

  static PartyView? maybe(dynamic v) => _m(v) == null ? null : PartyView.fromJson(_m(v)!);
}

class Hold {
  Hold({required this.id, required this.type, required this.status, this.customerMessage, this.placedAt});
  final String id;
  final String type;
  final String status;
  final String? customerMessage;
  final DateTime? placedAt;
  bool get active => status == 'ACTIVE';

  factory Hold.fromJson(Map<String, dynamic> j) => Hold(
        id: _sv(j['id']),
        type: _sv(j['type']),
        status: _sv(j['status']),
        customerMessage: _s(j['customerMessage']),
        placedAt: _t(j['placedAt']),
      );
}

class BlockedAction {
  BlockedAction({required this.action, required this.code, required this.message, this.details = const {}});
  final String action;
  final String code;
  final String message;
  final Map<String, dynamic> details;

  factory BlockedAction.fromJson(Map<String, dynamic> j) => BlockedAction(
        action: _sv(j['action']),
        code: _sv(j['code']),
        message: _sv(j['message']),
        details: _m(j['details']) ?? const {},
      );
}

class SurchargeBreakdown {
  SurchargeBreakdown({
    this.declaredWeightGrams,
    this.actualWeightGrams,
    this.rawDifferenceGrams,
    this.toleranceGrams,
    this.incrementGrams,
    this.billableDifferenceGrams,
    this.extraUnits,
    this.ratePerIncrementPaise,
    this.lines = const [],
    this.totalPaise,
    this.tariffVersion,
    this.display = const {},
  });
  final int? declaredWeightGrams;
  final int? actualWeightGrams;
  final int? rawDifferenceGrams;
  final int? toleranceGrams;
  final int? incrementGrams;
  final int? billableDifferenceGrams;
  final int? extraUnits;
  final int? ratePerIncrementPaise;
  final List<BreakdownLine> lines;
  final int? totalPaise;
  final int? tariffVersion;

  /// Server-rendered strings: declared, actual, rawDifference, billableDifference, total.
  final Map<String, String> display;

  BreakdownLine? line(String code) {
    for (final l in lines) {
      if (l.code == code) return l;
    }
    return null;
  }

  factory SurchargeBreakdown.fromJson(Map<String, dynamic>? j) => SurchargeBreakdown(
        declaredWeightGrams: _i(j?['declaredWeightGrams']),
        actualWeightGrams: _i(j?['actualWeightGrams']),
        rawDifferenceGrams: _i(j?['rawDifferenceGrams']),
        toleranceGrams: _i(j?['toleranceGrams']),
        incrementGrams: _i(j?['incrementGrams']),
        billableDifferenceGrams: _i(j?['billableDifferenceGrams']),
        extraUnits: _i(j?['extraUnits']),
        ratePerIncrementPaise: _i(j?['ratePerIncrementPaise']),
        lines: _l(j?['lines']).map(BreakdownLine.fromJson).toList(),
        totalPaise: _i(j?['totalPaise']),
        tariffVersion: _i(j?['tariffVersion']),
        display: (_m(j?['display']) ?? const {}).map((k, v) => MapEntry(k, '$v')),
      );
}

class SurchargeQuote {
  SurchargeQuote({
    required this.id,
    this.version,
    required this.status,
    this.totalPaise = 0,
    this.taxRateBps,
    this.tariffVersion,
    this.paymentDeadline,
    required this.breakdown,
    this.invoiceId,
    this.customerAcknowledgedAt,
  });
  final String id;
  final int? version;
  final String status;
  final int totalPaise;
  final int? taxRateBps;
  final int? tariffVersion;
  final DateTime? paymentDeadline;
  final SurchargeBreakdown breakdown;
  final String? invoiceId;
  final DateTime? customerAcknowledgedAt;

  factory SurchargeQuote.fromJson(Map<String, dynamic> j) => SurchargeQuote(
        id: _sv(j['id'] ?? j['quoteId']),
        version: _i(j['version']),
        status: _sv(j['status'], 'OPEN'),
        totalPaise: _i(j['totalPaise']) ?? 0,
        taxRateBps: _i(j['taxRateBps']),
        tariffVersion: _i(j['tariffVersion']),
        paymentDeadline: _t(j['paymentDeadline']),
        breakdown: SurchargeBreakdown.fromJson(_m(j['breakdown'])),
        invoiceId: _s(j['invoiceId']),
        customerAcknowledgedAt: _t(j['customerAcknowledgedAt']),
      );

  static SurchargeQuote? maybe(dynamic v) => _m(v) == null ? null : SurchargeQuote.fromJson(_m(v)!);
}

class SurchargeStatus {
  SurchargeStatus({
    this.customerLabel = 'NONE',
    this.currentQuote,
    this.invoice,
    this.latestIntent,
    this.amountDuePaise = 0,
    this.amountDueDisplay,
    this.paymentDeadline,
    this.deadlinePassed = false,
    this.disputed = false,
  });
  final String customerLabel;
  final SurchargeQuote? currentQuote;
  final Invoice? invoice;
  final PaymentIntent? latestIntent;
  final int amountDuePaise;
  final String? amountDueDisplay;
  final DateTime? paymentDeadline;
  final bool deadlinePassed;
  final bool disputed;

  /// Invoice to pay — never computed; taken from the server objects.
  String? get payableInvoiceId => invoice?.id ?? currentQuote?.invoiceId;

  factory SurchargeStatus.fromJson(Map<String, dynamic>? j) => SurchargeStatus(
        customerLabel: _sv(j?['customerLabel'], 'NONE'),
        currentQuote: SurchargeQuote.maybe(j?['currentQuote']),
        invoice: Invoice.maybe(j?['invoice']),
        latestIntent: PaymentIntent.maybe(j?['latestIntent']),
        amountDuePaise: _i(j?['amountDuePaise']) ?? 0,
        amountDueDisplay: _s(j?['amountDueDisplay']),
        paymentDeadline: _t(j?['paymentDeadline']),
        deadlinePassed: _b(j?['deadlinePassed']),
        disputed: _b(j?['disputed']),
      );
}

class ShipmentRoute {
  ShipmentRoute({this.routeName, this.operatorName, this.vehicleReg, this.origin, this.destination, this.plannedDepartureAt, this.plannedArrivalAt, this.loadGateEnabled = false});
  final String? routeName;
  final String? operatorName;
  final String? vehicleReg;
  final StopRef? origin;
  final StopRef? destination;
  final DateTime? plannedDepartureAt;
  final DateTime? plannedArrivalAt;
  final bool loadGateEnabled;

  factory ShipmentRoute.fromJson(Map<String, dynamic>? j) => ShipmentRoute(
        routeName: _s(j?['routeName']),
        operatorName: _s(j?['operatorName']),
        vehicleReg: _s(j?['vehicleReg']),
        origin: StopRef.maybe(j?['origin']),
        destination: StopRef.maybe(j?['destination']),
        plannedDepartureAt: _t(j?['plannedDepartureAt']),
        plannedArrivalAt: _t(j?['plannedArrivalAt']),
        loadGateEnabled: _b(j?['loadGateEnabled']),
      );
}

class BaseFareStatus {
  BaseFareStatus({this.invoiceId, this.totalPaise, this.status, this.paymentExpiresAt});
  final String? invoiceId;
  final int? totalPaise;
  final String? status;
  final DateTime? paymentExpiresAt;

  factory BaseFareStatus.fromJson(Map<String, dynamic>? j) => BaseFareStatus(
        invoiceId: _s(j?['invoiceId']),
        totalPaise: _i(j?['totalPaise']),
        status: _s(j?['status']),
        paymentExpiresAt: _t(j?['paymentExpiresAt']),
      );
}

class ShipmentView {
  ShipmentView({
    required this.id,
    this.dcn,
    this.bookingId,
    required this.state,
    this.stateLabel,
    this.version,
    this.qrPayload,
    required this.route,
    this.serviceOption,
    this.sender,
    this.receiver,
    this.category,
    this.itemDescription,
    this.declaredWeightGrams,
    this.declaredWeightDisplay,
    this.latestEvidenceId,
    required this.baseFare,
    required this.surcharge,
    this.cutoffAt,
    this.cutoffPassed = false,
    this.warehouseRequired = false,
    this.warehouseRequiredReason,
    this.holds = const [],
    this.warehouseInfo,
    this.warehousePresent = false,
    this.warehouseAmountDuePaise,
    this.warehouseReceivedAt,
    this.pickupRequirements = const [],
    this.allowedActions = const [],
    this.blockedActions = const [],
    this.serverTime,
  });

  final String id;
  final String? dcn;
  final String? bookingId;
  final String state;
  final String? stateLabel;
  final int? version;
  final String? qrPayload;
  final ShipmentRoute route;
  final String? serviceOption;
  final PartyView? sender;
  final PartyView? receiver;
  final String? category;
  final String? itemDescription;
  final int? declaredWeightGrams;
  final String? declaredWeightDisplay;

  /// Scale photo of the current measurement ("See weight evidence").
  final String? latestEvidenceId;
  final BaseFareStatus baseFare;
  final SurchargeStatus surcharge;
  final DateTime? cutoffAt;
  final bool cutoffPassed;
  final bool warehouseRequired;
  final String? warehouseRequiredReason;
  final List<Hold> holds;
  final Warehouse? warehouseInfo;

  /// `warehouse != null` in the response.
  final bool warehousePresent;
  final int? warehouseAmountDuePaise;
  final DateTime? warehouseReceivedAt;
  final List<String> pickupRequirements;
  final List<String> allowedActions;
  final List<BlockedAction> blockedActions;
  final DateTime? serverTime;

  bool isAllowed(String action) => allowedActions.contains(action);

  BlockedAction? blocker(String action) {
    for (final b in blockedActions) {
      if (b.action == action) return b;
    }
    return null;
  }

  List<Hold> get activeHolds => holds.where((h) => h.active).toList();

  factory ShipmentView.fromJson(Map<String, dynamic> j) {
    final parties = _m(j['parties']);
    final parcel = _m(j['parcel']);
    final weight = _m(j['weight']);
    final latest = _m(weight?['latestMeasurement']);
    final wh = _m(j['warehouse']);
    final inv = _m(wh?['inventory']);
    return ShipmentView(
      id: _sv(j['id']),
      dcn: _s(j['dcn']),
      bookingId: _s(j['bookingId']),
      state: _sv(j['state']),
      stateLabel: _s(j['stateLabel']),
      version: _i(j['version']),
      qrPayload: _s(_m(j['qr'])?['payload'] ?? _m(j['qr'])?['token']),
      route: ShipmentRoute.fromJson(_m(j['route'])),
      serviceOption: _s(j['serviceOption']),
      sender: PartyView.maybe(parties?['sender']),
      receiver: PartyView.maybe(parties?['receiver']),
      category: _s(parcel?['category']),
      itemDescription: _s(parcel?['itemDescription']),
      declaredWeightGrams: _i(parcel?['declaredWeightGrams']),
      declaredWeightDisplay: _s(parcel?['declaredWeightDisplay']),
      latestEvidenceId: _s(latest?['evidenceId']),
      baseFare: BaseFareStatus.fromJson(_m(j['baseFare'])),
      surcharge: SurchargeStatus.fromJson(_m(j['surcharge'])),
      cutoffAt: _t(j['cutoffAt']),
      cutoffPassed: _b(j['cutoffPassed']),
      warehouseRequired: _b(j['warehouseRequired']),
      warehouseRequiredReason: _s(j['warehouseRequiredReason']),
      holds: _l(j['holds']).map(Hold.fromJson).toList(),
      warehouseInfo: Warehouse.maybe(wh?['info']),
      warehousePresent: wh != null,
      warehouseAmountDuePaise: _i(inv?['amountDuePaise']),
      warehouseReceivedAt: _t(inv?['receivedAt']),
      pickupRequirements: _sl(j['pickupRequirements']),
      allowedActions: _sl(j['allowedActions']),
      blockedActions: _l(j['blockedActions']).map(BlockedAction.fromJson).toList(),
      serverTime: _t(j['serverTime']),
    );
  }
}

class TimelineEntry {
  TimelineEntry({this.at, required this.kind, required this.title, this.detail, this.state});
  final DateTime? at;
  final String kind;
  final String title;
  final String? detail;
  final String? state;

  factory TimelineEntry.fromJson(Map<String, dynamic> j) => TimelineEntry(
        at: _t(j['at']),
        kind: _sv(j['kind']),
        title: _sv(j['title']),
        detail: _s(j['detail']),
        state: _s(j['state']),
      );
}

// ─── Disputes / support / notifications / evidence ───

class Dispute {
  Dispute({required this.id, this.caseNumber, this.status});
  final String id;
  final String? caseNumber;
  final String? status;

  factory Dispute.fromJson(Map<String, dynamic> j) =>
      Dispute(id: _sv(j['id']), caseNumber: _s(j['caseNumber']), status: _s(j['status']));
}

class Ticket {
  Ticket({required this.id, this.ticketNumber, this.category, required this.status, this.subject, this.shipmentId, this.dcn, this.createdAt, this.updatedAt});
  final String id;
  final String? ticketNumber;
  final String? category;
  final String status;
  final String? subject;
  final String? shipmentId;
  final String? dcn;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Ticket.fromJson(Map<String, dynamic> j) => Ticket(
        id: _sv(j['id']),
        ticketNumber: _s(j['ticketNumber']),
        category: _s(j['category']),
        status: _sv(j['status'], 'OPEN'),
        subject: _s(j['subject']),
        shipmentId: _s(j['shipmentId']),
        dcn: _s(j['dcn']),
        createdAt: _t(j['createdAt']),
        updatedAt: _t(j['updatedAt']),
      );
}

class TicketMessage {
  TicketMessage({required this.id, this.authorRole, this.authorName, required this.body, this.createdAt});
  final String id;
  final String? authorRole;
  final String? authorName;
  final String body;
  final DateTime? createdAt;

  bool get fromCustomer => authorRole == null || authorRole == 'customer';

  factory TicketMessage.fromJson(Map<String, dynamic> j) => TicketMessage(
        id: _sv(j['id']),
        authorRole: _s(j['authorRole']),
        authorName: _s(j['authorName']),
        body: _sv(j['body']),
        createdAt: _t(j['createdAt']),
      );
}

class TicketDetail {
  TicketDetail(this.ticket, this.messages);
  final Ticket ticket;
  final List<TicketMessage> messages;

  factory TicketDetail.fromJson(Map<String, dynamic> j) =>
      TicketDetail(Ticket.fromJson(j), _l(j['messages']).map(TicketMessage.fromJson).toList());
}

class CoreNotification {
  CoreNotification({required this.id, this.templateCode, this.shipmentId, required this.title, required this.body, this.data = const {}, this.readAt, this.createdAt});
  final String id;
  final String? templateCode;
  final String? shipmentId;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime? createdAt;
  bool get isRead => readAt != null;

  factory CoreNotification.fromJson(Map<String, dynamic> j) => CoreNotification(
        id: _sv(j['id']),
        templateCode: _s(j['templateCode']),
        shipmentId: _s(j['shipmentId']),
        title: _sv(j['title'], 'Notification'),
        body: _sv(j['body']),
        data: _m(j['data']) ?? const {},
        readAt: _t(j['readAt']),
        createdAt: _t(j['createdAt']),
      );
}

class Evidence {
  Evidence({required this.id, this.kind, this.contentType, this.downloadUrl});
  final String id;
  final String? kind;
  final String? contentType;

  /// Signed URL relative to the API origin.
  final String? downloadUrl;

  factory Evidence.fromJson(Map<String, dynamic> j) => Evidence(
        id: _sv(j['id']),
        kind: _s(j['kind']),
        contentType: _s(j['contentType']),
        downloadUrl: _s(j['downloadUrl']),
      );
}
