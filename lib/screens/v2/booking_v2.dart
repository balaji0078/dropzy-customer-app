import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core_api/action_key.dart';
import '../../core_api/format.dart';
import '../../core_api/labels.dart';
import '../../core_api/models.dart';
import '../../core_api/payment_coordinator.dart';
import '../../core_api/session.dart';
import '../../widgets/common.dart';
import '../../widgets/v2/core_widgets.dart';
import '../../widgets/v2/photo_picker.dart';
import 'core_app.dart';
import 'payment_flow_screen.dart';

/// C5–C8 — 4-step booking: Route & date → Parcel → Review & quote →
/// Sender & receiver → `POST /bookings` → `POST /payments/intents` → C9.
/// The fare is always the server quote; the client never computes money.
class CoreBookingScreen extends StatefulWidget {
  const CoreBookingScreen({super.key});
  @override
  State<CoreBookingScreen> createState() => _CoreBookingScreenState();
}

class _CoreBookingScreenState extends State<CoreBookingScreen> {
  static const _stepTitles = ['Route', 'Parcel', 'Review', 'Details'];
  late final CoreServices _svc = context.read<CoreServices>();
  int _step = 0;

  // Step 1 — route & date
  List<StopRef>? _origins;
  List<StopRef>? _destinations;
  StopRef? _origin;
  StopRef? _destination;
  late final List<DateTime> _dates = bookableIstDates(DateTime.now());
  int _dateIndex = 0;
  List<TripOffer>? _trips;
  TripOffer? _trip;
  bool _loadingTrips = false;
  Object? _step1Error;

  // Step 2 — parcel
  ParcelPolicy? _policy;
  Object? _policyError;
  String? _category;
  String _unit = 'kg';
  final _weight = TextEditingController();
  final _length = TextEditingController();
  final _width = TextEditingController();
  final _height = TextEditingController();
  String _serviceOption = 'STOP_HANDOVER';
  final _description = TextEditingController();
  final _declaredValue = TextEditingController();
  PickedPhoto? _photo;

  // Step 3 — quote
  BookingQuote? _quote;
  bool _quoting = false;
  Timer? _expiryTimer;
  bool _ackProhibited = false;
  bool _ackWeight = false;

  // Step 4 — parties
  final _senderName = TextEditingController();
  final _senderPhone = TextEditingController();
  final _receiverName = TextEditingController();
  final _receiverPhone = TextEditingController();
  final _bookingKey = ActionKey();
  final _intentKey = ActionKey();
  BookingCreated? _created;
  bool _paying = false;
  String? _payError;

  @override
  void initState() {
    super.initState();
    final me = context.read<CoreSession>().me;
    _senderName.text = me?.name ?? '';
    _senderPhone.text = localPhone(me?.phone);
    for (final c in [_weight, _length, _width, _height, _description, _declaredValue]) {
      c.addListener(_parcelChanged);
    }
    for (final c in [_senderName, _senderPhone, _receiverName, _receiverPhone]) {
      c.addListener(_partiesChanged);
    }
    _loadOrigins();
    _loadPolicy();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    for (final c in [
      _weight, _length, _width, _height, _description, _declaredValue,
      _senderName, _senderPhone, _receiverName, _receiverPhone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _parcelChanged() {
    // Editing the parcel = a new quote (PRICING.md §5.1).
    if (_quote != null && _created == null) _setQuote(null);
    setState(() {});
  }

  void _partiesChanged() {
    if (_created == null) _bookingKey.reset();
    setState(() {});
  }

  // ─── Loading ───

  Future<void> _loadOrigins() async {
    try {
      final o = await _svc.api.stops(role: 'origin');
      if (mounted) setState(() => _origins = o);
    } catch (e) {
      if (mounted) setState(() => _step1Error = e);
    }
  }

  Future<void> _loadDestinations() async {
    final origin = _origin;
    if (origin == null) return;
    try {
      final d = await _svc.api.stops(role: 'destination', originStopId: origin.id);
      if (mounted && _origin?.id == origin.id) setState(() => _destinations = d);
    } catch (e) {
      if (mounted) setState(() => _step1Error = e);
    }
  }

  Future<void> _loadTrips() async {
    final o = _origin, d = _destination;
    if (o == null || d == null) return;
    setState(() {
      _loadingTrips = true;
      _trips = null;
      _trip = null;
      _step1Error = null;
    });
    try {
      final t = await _svc.api.trips(originStopId: o.id, destinationStopId: d.id, date: istDateParam(_dates[_dateIndex]));
      if (mounted) setState(() => _trips = t);
    } catch (e) {
      if (mounted) setState(() => _step1Error = e);
    } finally {
      if (mounted) setState(() => _loadingTrips = false);
    }
  }

  Future<void> _loadPolicy() async {
    try {
      final p = await _svc.api.parcelPolicy();
      if (!mounted) return;
      setState(() {
        _policy = p;
        _policyError = null;
        _category ??= p.categories.isNotEmpty ? p.categories.first : null;
        if (!p.allowedInputUnits.contains(_unit)) _unit = p.allowedInputUnits.first;
      });
    } catch (e) {
      if (mounted) setState(() => _policyError = e);
    }
  }

  // ─── Step 2 validation ───

  String? get _weightError {
    if (_weight.text.isEmpty) return null;
    return validateDeclaredWeight(_weight.text, _unit,
        minGrams: _policy?.minDeclaredGrams, maxGrams: _policy?.maxDeclaredGrams);
  }

  int? _dim(TextEditingController c) => c.text.isEmpty ? null : int.tryParse(c.text);

  String? get _dimsError {
    final vals = [_length, _width, _height];
    final filled = vals.where((c) => c.text.isNotEmpty).length;
    if (filled == 0) return null;
    if (filled < 3) return 'Enter length, width and height, or leave all empty.';
    final max = _policy?.maxDimensionCm ?? 200;
    for (final c in vals) {
      final v = _dim(c);
      if (v == null || v < 1 || v > max) return 'Each side must be between 1 and $max cm.';
    }
    return null;
  }

  String? get _valueError {
    if (_declaredValue.text.trim().isEmpty) return null;
    return rupeesToPaise(_declaredValue.text) == null ? 'Enter an amount in rupees, e.g. 1500' : null;
  }

  bool get _parcelValid =>
      _category != null &&
      _weight.text.isNotEmpty &&
      _weightError == null &&
      _dimsError == null &&
      _valueError == null &&
      _description.text.trim().length >= 3;

  bool get _partiesValid =>
      _senderName.text.trim().isNotEmpty &&
      isValidPhone(_senderPhone.text) &&
      _receiverName.text.trim().isNotEmpty &&
      isValidPhone(_receiverPhone.text);

  // ─── Quote ───

  void _setQuote(BookingQuote? q) {
    _expiryTimer?.cancel();
    _quote = q;
    final exp = q?.expiresAt;
    if (q != null && exp != null) {
      final wait = exp.difference(DateTime.now());
      _expiryTimer = Timer(wait.isNegative ? Duration.zero : wait, () {
        // Re-quote automatically when the price expires while on screen.
        if (mounted && _step >= 2 && _created == null) _requestQuote(silent: true);
      });
    }
  }

  Map<String, dynamic> _quoteRequest() => {
        'tripId': _trip!.tripId,
        'originStopId': _origin!.id,
        'destinationStopId': _destination!.id,
        'category': _category,
        'serviceOption': _serviceOption,
        'declaredWeight': {'value': _weight.text, 'unit': _unit},
        if (_dim(_length) != null)
          'dimensionsCm': {'length': _dim(_length), 'width': _dim(_width), 'height': _dim(_height)},
      };

  Future<bool> _requestQuote({bool silent = false}) async {
    if (_trip == null || !_parcelValid) return false;
    setState(() => _quoting = true);
    try {
      final q = await _svc.api.quote(_quoteRequest(), idempotencyKey: newIdempotencyKey());
      if (!mounted) return false;
      setState(() => _setQuote(q));
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      if (e.code == 'CAPACITY_UNAVAILABLE') {
        _backToTrips(e.message);
      } else if (!silent) {
        showApiError(context, e);
      } else {
        setState(() => _setQuote(null));
        showApiError(context, e);
      }
      return false;
    } finally {
      if (mounted) setState(() => _quoting = false);
    }
  }

  void _backToTrips(String message) {
    showToast(context, message);
    setState(() {
      _setQuote(null);
      _trip = null;
      _step = 0;
    });
    _loadTrips();
  }

  // ─── Create + pay (C8) ───

  Map<String, dynamic> _bookingRequest() {
    final value = rupeesToPaise(_declaredValue.text);
    return {
      'quoteId': _quote!.quoteId,
      'sender': {'name': _senderName.text.trim(), 'phone': _senderPhone.text},
      'receiver': {'name': _receiverName.text.trim(), 'phone': _receiverPhone.text},
      'itemDescription': _description.text.trim(),
      if (value != null) 'declaredValuePaise': value,
      'prohibitedItemsAcknowledged': true,
      'weightPolicyAcknowledged': true,
    };
  }

  Future<void> _pay() async {
    if (_quote == null || !_partiesValid || _paying) return;
    setState(() {
      _paying = true;
      _payError = null;
    });
    try {
      var created = _created;
      if (created == null) {
        try {
          created = await _bookingKey.run((k) => _svc.api.createBooking(_bookingRequest(), idempotencyKey: k));
        } on ApiException catch (e) {
          if (!mounted) return;
          if (e.code == 'QUOTE_EXPIRED') {
            showToast(context, e.message); // "Price expired — refreshing."
            setState(() => _step = 2);
            await _requestQuote(silent: true);
            return;
          }
          if (e.code == 'CAPACITY_UNAVAILABLE') {
            _backToTrips(e.message);
            return;
          }
          rethrow;
        }
        if (!mounted) return;
        final made = created!;
        setState(() => _created = made);
        _uploadParcelPhoto(made.shipment.id);
      }
      final intent = await _intentKey.run((k) => _svc.api.createPaymentIntent(created!.invoice.id, idempotencyKey: k));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => PaymentFlowScreen.checkout(
          intent: intent,
          purpose: PaymentPurpose.baseFare,
          shipmentId: created!.shipment.id,
        ),
      ));
    } on ApiException catch (e) {
      if (mounted) setState(() => _payError = e.message);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  /// Optional parcel photo, bound to the new shipment (`POST /evidence`,
  /// kind PARCEL_PHOTO). Never blocks payment.
  void _uploadParcelPhoto(String shipmentId) {
    final p = _photo;
    if (p == null || p.evidenceId != null) return;
    _svc.api
        .uploadEvidence(
          bytes: p.bytes,
          filename: p.filename,
          contentType: p.contentType,
          kind: 'PARCEL_PHOTO',
          shipmentId: shipmentId,
          capturedAt: p.capturedAt,
          idempotencyKey: p.uploadKey,
        )
        .then((ev) => p.evidenceId = ev.id)
        .catchError((_) => '');
  }

  // ─── Navigation ───

  bool get _canNext {
    switch (_step) {
      case 0:
        return _trip != null && _trip!.bookable;
      case 1:
        return _parcelValid && !_quoting;
      case 2:
        return _quote != null && _ackProhibited && _ackWeight && !_quoting;
      default:
        return false;
    }
  }

  Future<void> _next() async {
    if (!_canNext) return;
    if (_step == 1) {
      if (await _requestQuote() && mounted) setState(() => _step = 2);
      return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0 || _created != null) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0 || _created != null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Book a parcel'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
        ),
        body: Column(children: [
          _StepHeader(titles: _stepTitles, current: _step),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
              if (_step == 0) ..._routeStep(),
              if (_step == 1) ..._parcelStep(),
              if (_step == 2) ..._reviewStep(),
              if (_step == 3) ..._partiesStep(),
            ]),
          ),
          if (_step < 3)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: BusyButton(
                  label: _step == 1 ? 'Get price' : 'Continue',
                  busy: _quoting && _step >= 1,
                  onPressed: _canNext ? _next : null,
                ),
              ),
            ),
        ]),
      ),
    );
  }

  // ─── C5 ───

  List<Widget> _routeStep() {
    if (_origins == null) {
      return [
        if (_step1Error != null)
          ErrorPanel(error: _step1Error!, onRetry: () {
            setState(() => _step1Error = null);
            _loadOrigins();
          })
        else
          const Padding(padding: EdgeInsets.all(40), child: LoadingView()),
      ];
    }
    return [
      const SectionTitle('From'),
      DropdownButtonFormField<String>(
        initialValue: _origin?.id,
        isExpanded: true,
        decoration: const InputDecoration(hintText: 'Origin stop', prefixIcon: Icon(Icons.my_location_rounded)),
        items: [for (final s in _origins!) DropdownMenuItem(value: s.id, child: Text(s.title, overflow: TextOverflow.ellipsis))],
        onChanged: (id) {
          setState(() {
            _origin = _origins!.firstWhere((s) => s.id == id);
            _destination = null;
            _destinations = null;
            _trips = null;
            _trip = null;
            _setQuote(null);
          });
          _loadDestinations();
        },
      ),
      const SizedBox(height: 16),
      const SectionTitle('To'),
      DropdownButtonFormField<String>(
        key: ValueKey('dest-${_origin?.id}'),
        initialValue: _destination?.id,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: _origin == null ? 'Choose the origin first' : 'Destination stop',
          prefixIcon: const Icon(Icons.place_rounded),
        ),
        items: [
          for (final s in _destinations ?? const <StopRef>[])
            DropdownMenuItem(value: s.id, child: Text(s.title, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: _destinations == null
            ? null
            : (id) {
                setState(() {
                  _destination = _destinations!.firstWhere((s) => s.id == id);
                  _setQuote(null);
                });
                _loadTrips();
              },
      ),
      const SizedBox(height: 16),
      const SectionTitle('Travel date'),
      SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _dates.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => ChoiceChip(
            label: Text(i == 0 ? 'Today' : (i == 1 ? 'Tomorrow' : formatIstDay(_dates[i]))),
            selected: _dateIndex == i,
            selectedColor: DropzyColors.primaryTint,
            onSelected: (_) {
              setState(() {
                _dateIndex = i;
                _setQuote(null);
              });
              _loadTrips();
            },
          ),
        ),
      ),
      const SizedBox(height: 20),
      if (_destination != null) ...[
        const SectionTitle('Buses'),
        if (_loadingTrips)
          const Padding(padding: EdgeInsets.all(24), child: LoadingView())
        else if (_step1Error != null)
          ErrorPanel(error: _step1Error!, onRetry: _loadTrips)
        else if ((_trips ?? const []).isEmpty)
          const SoftCard(
            child: Text('No buses on this date. Try another day.', style: TextStyle(color: DropzyColors.inkSoft)),
          )
        else
          for (final t in _trips!) ...[_tripCard(t), const SizedBox(height: 10)],
      ],
    ];
  }

  Widget _tripCard(TripOffer t) {
    final selected = _trip?.tripId == t.tripId;
    final fg = t.bookable ? DropzyColors.ink : DropzyColors.inkSoft;
    return Opacity(
      opacity: t.bookable ? 1 : 0.5,
      child: Material(
        color: selected ? DropzyColors.primaryTint : DropzyColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: t.bookable
              ? () => setState(() {
                    _trip = t;
                    _setQuote(null);
                    if (t.destinationWarehouse == null) _serviceOption = 'STOP_HANDOVER';
                  })
              : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? DropzyColors.primary : DropzyColors.line, width: selected ? 1.6 : 1),
            ),
            child: Row(children: [
              Icon(Icons.directions_bus_rounded, color: t.bookable ? DropzyColors.primary : DropzyColors.inkSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.operatorName ?? t.routeName ?? 'Bus',
                      style: TextStyle(fontWeight: FontWeight.w800, color: fg)),
                  const SizedBox(height: 4),
                  if (t.departureAtOrigin != null)
                    Text('Departs ${formatIst(t.departureAtOrigin!)}', style: TextStyle(color: fg, fontSize: 13)),
                  if (t.arrivalAtDestination != null)
                    Text('Arrives ${formatIst(t.arrivalAtDestination!)}',
                        style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 13)),
                  if (t.bookingClosesAt != null && t.bookable)
                    Text('Book by ${formatIst(t.bookingClosesAt!)}',
                        style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 12.5)),
                ]),
              ),
              if (!t.bookable)
                const LabelChip(text: 'Full', icon: Icons.block_rounded, tone: ChipTone.neutral, dense: true)
              else if (selected)
                const Icon(Icons.check_circle_rounded, color: DropzyColors.primary),
            ]),
          ),
        ),
      ),
    );
  }

  // ─── C6 ───

  List<Widget> _parcelStep() {
    final p = _policy;
    if (p == null) {
      return [
        if (_policyError != null)
          ErrorPanel(error: _policyError!, onRetry: _loadPolicy)
        else
          const Padding(padding: EdgeInsets.all(40), child: LoadingView()),
      ];
    }
    final warehouse = _trip?.destinationWarehouse;
    final options = p.serviceOptions.where((o) => o != 'WAREHOUSE_PICKUP' || warehouse != null).toList();
    return [
      const SectionTitle('What are you sending?'),
      DropdownButtonFormField<String>(
        initialValue: _category,
        decoration: const InputDecoration(labelText: 'Category'),
        items: [for (final c in p.categories) DropdownMenuItem(value: c, child: Text(categoryLabel(c)))],
        onChanged: (v) {
          _category = v;
          _parcelChanged();
        },
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _description,
        inputFormatters: [LengthLimitingTextInputFormatter(300)],
        decoration: const InputDecoration(labelText: 'Item description', hintText: 'e.g. 2 cotton sarees'),
      ),
      const SizedBox(height: 20),
      const SectionTitle('Declared weight'),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: TextField(
            key: const ValueKey('declared-weight'),
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(_unit == 'g' ? RegExp(r'[0-9]') : RegExp(r'[0-9.]')),
              LengthLimitingTextInputFormatter(_unit == 'g' ? 6 : 7),
            ],
            decoration: InputDecoration(hintText: _unit == 'g' ? 'e.g. 500' : 'e.g. 0.5', errorText: _weightError, errorMaxLines: 2),
          ),
        ),
        const SizedBox(width: 10),
        SegmentedButton<String>(
          segments: [for (final u in p.allowedInputUnits) ButtonSegment(value: u, label: Text(u))],
          selected: {_unit},
          showSelectedIcon: false,
          onSelectionChanged: (s) {
            _unit = s.first;
            _weight.clear();
            _parcelChanged();
          },
        ),
      ]),
      if (p.minDeclaredGrams != null && p.maxDeclaredGrams != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('Between ${formatKg(p.minDeclaredGrams!)} and ${formatKg(p.maxDeclaredGrams!)}.',
              style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 12.5)),
        ),
      const SizedBox(height: 20),
      const SectionTitle('Size in cm (optional)'),
      Row(children: [
        Expanded(child: _dimField(_length, 'L')),
        const SizedBox(width: 8),
        Expanded(child: _dimField(_width, 'W')),
        const SizedBox(width: 8),
        Expanded(child: _dimField(_height, 'H')),
      ]),
      if (_dimsError != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(_dimsError!, style: const TextStyle(color: DropzyColors.danger, fontSize: 12.5)),
        ),
      const SizedBox(height: 20),
      const SectionTitle('Delivery'),
      RadioGroup<String>(
        groupValue: _serviceOption,
        onChanged: (v) {
          _serviceOption = v ?? _serviceOption;
          _parcelChanged();
        },
        child: Column(children: [
          for (final o in options)
            RadioListTile<String>(
              value: o,
              contentPadding: EdgeInsets.zero,
              activeColor: DropzyColors.primary,
              title: Text(o == 'WAREHOUSE_PICKUP'
                  ? 'Pick up from ${warehouse?.name ?? 'the warehouse'}'
                  : 'Hand over at ${_destination?.name ?? 'the destination stop'}'),
              subtitle: o == 'WAREHOUSE_PICKUP' && warehouse?.address != null ? Text(warehouse!.address!) : null,
            ),
        ]),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _declaredValue,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration: InputDecoration(labelText: 'Declared value in ₹ (optional)', errorText: _valueError),
      ),
      const SizedBox(height: 20),
      const SectionTitle('Parcel photo (optional)'),
      PhotoStrip(
        photos: [if (_photo != null) _photo!],
        max: 1,
        onAdd: () async {
          final p = await pickPhoto(context);
          if (p != null && mounted) setState(() => _photo = p);
        },
        onRemove: (_) => setState(() => _photo = null),
      ),
    ];
  }

  Widget _dimField(TextEditingController c, String hint) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
        decoration: InputDecoration(hintText: hint),
      );

  // ─── C7 ───

  List<Widget> _reviewStep() {
    final q = _quote;
    if (q == null) {
      return [
        const Padding(padding: EdgeInsets.all(30), child: LoadingView(message: 'Getting the latest price…')),
      ];
    }
    final texts = q.policy?.texts ?? _policy?.texts ?? const PolicyTexts();
    return [
      SoftCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_origin?.shortName ?? q.origin?.shortName ?? ''} → ${_destination?.shortName ?? q.destination?.shortName ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          if (q.departureAtOrigin != null) ...[
            const SizedBox(height: 4),
            Text('Departs ${formatIst(q.departureAtOrigin!)}', style: const TextStyle(color: DropzyColors.inkSoft)),
          ],
          const SizedBox(height: 10),
          Text('Declared weight: ${q.declaredWeightDisplay ?? (q.declaredWeightGrams == null ? '—' : formatKg(q.declaredWeightGrams!))}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const Divider(height: 22),
          for (final l in q.fare.lines) InfoRow(l.label, formatInr(l.amountPaise)),
          const Divider(height: 18),
          InfoRow('Total', moneyText(q.fare.totalPaise, q.fare.totalDisplay), emphasize: true),
          if (q.expiresAt != null)
            Ticker(
              period: const Duration(seconds: 5),
              builder: (_, now) => Text(
                q.expiresAt!.isAfter(now)
                    ? 'Price valid for ${formatCountdown(q.expiresAt!.difference(now))}'
                    : 'Refreshing price…',
                style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 12),
              ),
            ),
        ]),
      ),
      if (q.paymentCutoffAt != null) ...[
        const SizedBox(height: 14),
        TintCard(
          color: DropzyColors.warning,
          padding: const EdgeInsets.all(12),
          child: Text(
            'If your parcel is heavier than declared, the extra charge must be paid before ${formatIstDeadline(q.paymentCutoffAt!)}.',
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
          ),
        ),
      ],
      for (final t in [texts.weightPolicy, texts.restrictedItems, texts.cancellation])
        if (t != null && t.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(t, style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 13, height: 1.4)),
        ],
      const SizedBox(height: 14),
      CheckboxListTile(
        value: _ackProhibited,
        onChanged: (v) => setState(() => _ackProhibited = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        activeColor: DropzyColors.primary,
        title: const Text('I confirm my parcel contains no prohibited items.'),
      ),
      CheckboxListTile(
        value: _ackWeight,
        onChanged: (v) => setState(() => _ackWeight = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        activeColor: DropzyColors.primary,
        title: const Text('I understand the parcel will be weighed and extra weight is charged.'),
      ),
    ];
  }

  // ─── C8 ───

  List<Widget> _partiesStep() {
    final locked = _created != null;
    final total = _quote == null ? '' : moneyText(_quote!.fare.totalPaise, _quote!.fare.totalDisplay);
    return [
      const SectionTitle('Sender'),
      TextField(
        controller: _senderName,
        enabled: !locked,
        textCapitalization: TextCapitalization.words,
        inputFormatters: [LengthLimitingTextInputFormatter(120)],
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      const SizedBox(height: 12),
      _phoneField(_senderPhone, locked),
      const SizedBox(height: 22),
      const SectionTitle('Receiver'),
      TextField(
        controller: _receiverName,
        enabled: !locked,
        textCapitalization: TextCapitalization.words,
        inputFormatters: [LengthLimitingTextInputFormatter(120)],
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      const SizedBox(height: 12),
      _phoneField(_receiverPhone, locked),
      const SizedBox(height: 8),
      const Text('The receiver gets an OTP by SMS at pickup.',
          style: TextStyle(color: DropzyColors.inkSoft, fontSize: 12.5)),
      if (locked) ...[
        const SizedBox(height: 16),
        const TintCard(
          color: DropzyColors.info,
          padding: EdgeInsets.all(12),
          child: Text('Booking created — complete the payment to confirm it.'),
        ),
      ],
      if (_payError != null) ...[
        const SizedBox(height: 16),
        TintCard(color: DropzyColors.danger, padding: const EdgeInsets.all(12), child: Text(_payError!)),
      ],
      const SizedBox(height: 24),
      BusyButton(
        label: 'Pay $total',
        icon: Icons.lock_rounded,
        busy: _paying,
        onPressed: (_partiesValid && _quote != null) ? _pay : null,
      ),
    ];
  }

  Widget _phoneField(TextEditingController c, bool locked) => TextField(
        controller: c,
        enabled: !locked,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        decoration: InputDecoration(
          labelText: 'Mobile number',
          prefixText: '+91 ',
          errorText: c.text.isEmpty || isValidPhone(c.text) ? null : 'Enter a valid 10-digit mobile number',
        ),
      );
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.titles, required this.current});
  final List<String> titles;
  final int current;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(children: [
        for (var i = 0; i < titles.length; i++) ...[
          Expanded(
            child: Column(children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= current ? DropzyColors.primary : DropzyColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Text('${i + 1}. ${titles[i]}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: i == current ? FontWeight.w800 : FontWeight.w600,
                    color: i <= current ? DropzyColors.ink : DropzyColors.inkSoft,
                  )),
            ]),
          ),
          if (i < titles.length - 1) const SizedBox(width: 6),
        ],
      ]),
    );
  }
}
