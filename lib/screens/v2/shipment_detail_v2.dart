import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core_api/action_key.dart';
import '../../core_api/format.dart';
import '../../core_api/gates.dart';
import '../../core_api/labels.dart';
import '../../core_api/models.dart';
import '../../core_api/payment_coordinator.dart';
import '../../core_api/poller.dart';
import '../../widgets/common.dart';
import '../../widgets/scenery.dart';
import '../../widgets/v2/core_widgets.dart';
import '../../widgets/v2/shipment_widgets.dart';
import '../../widgets/v2/surcharge_card.dart';
import 'core_app.dart';
import 'dispute_screen.dart';
import 'payment_flow_screen.dart';
import 'support_v2.dart';
import 'surcharge_pay_screen.dart';

/// C15 polling: 3 s while a payment is verifying, 10 s otherwise.
Duration shipmentPollInterval(ShipmentView? s) {
  if (s == null) return const Duration(seconds: 10);
  final sc = s.surcharge;
  final verifying = sc.customerLabel == 'VERIFYING' || sc.latestIntent?.status == 'PENDING_PROVIDER';
  return verifying ? const Duration(seconds: 3) : const Duration(seconds: 10);
}

/// C15 — shipment detail / tracking (server timeline, surcharge + warehouse
/// cards, QR, pickup requirements, cancel). No simulate/advance and no
/// receiver "confirm pickup" action exists in this build.
class ShipmentDetailV2 extends StatefulWidget {
  const ShipmentDetailV2({super.key, required this.shipmentId});
  final String shipmentId;
  @override
  State<ShipmentDetailV2> createState() => _ShipmentDetailV2State();
}

class _ShipmentDetailV2State extends State<ShipmentDetailV2> {
  late final CoreServices _svc = context.read<CoreServices>();
  ShipmentView? _s;
  List<TimelineEntry> _timeline = const [];
  Object? _error;
  bool _payingBase = false;
  final _baseKey = ActionKey();
  late final Poller _poller = Poller(task: _load, interval: () => shipmentPollInterval(_s));

  @override
  void initState() {
    super.initState();
    _poller.start();
  }

  @override
  void dispose() {
    _poller.stop();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _svc.api.shipment(widget.shipmentId),
        _svc.api.timeline(widget.shipmentId),
      ]);
      if (!mounted) return;
      final s = results[0] as ShipmentView;
      setState(() {
        _s = s;
        _timeline = results[1] as List<TimelineEntry>;
        _error = null;
      });
      if (isTerminalState(s.state)) _poller.stop();
    } catch (e) {
      if (mounted) setState(() => _error = e);
      rethrow;
    }
  }

  Future<void> _refresh() async {
    if (!_poller.isActive && _s != null && !isTerminalState(_s!.state)) _poller.start(immediate: false);
    await _poller.tick();
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) await _refresh();
  }

  Future<void> _payBaseFare(ShipmentView s) async {
    final invoiceId = s.baseFare.invoiceId;
    if (invoiceId == null) return;
    setState(() => _payingBase = true);
    try {
      final intent = await _baseKey.run((k) => _svc.api.createPaymentIntent(invoiceId, idempotencyKey: k));
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PaymentFlowScreen.checkout(intent: intent, purpose: PaymentPurpose.baseFare, shipmentId: s.id),
      ));
      if (mounted) await _refresh();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _payingBase = false);
    }
  }

  Future<void> _cancel(ShipmentView s) async {
    final cancelled = await showDialog<bool>(
      context: context,
      builder: (_) => _CancelDialog(shipment: s, services: _svc),
    );
    if (cancelled == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      body: RefreshIndicator(
        color: DropzyColors.primary,
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DropzyHero(
              title: s?.dcn ?? 'Your booking',
              subtitle: s == null ? null : '${s.route.origin?.shortName ?? '—'} → ${s.route.destination?.shortName ?? '—'}',
              height: 170,
              overlay: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              child: s == null
                  ? (_error != null
                      ? ErrorPanel(error: _error!, onRetry: _refresh, title: 'Could not load this shipment')
                      : const Padding(padding: EdgeInsets.all(40), child: LoadingView()))
                  : _content(s),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(ShipmentView s) {
    final sc = s.surcharge;
    final payBase = gateFor(s, 'PAY_BASE_FARE');
    final showBasePay = payBase.enabled || s.blocker('PAY_BASE_FARE') != null;
    final weight = s.declaredWeightDisplay ?? (s.declaredWeightGrams == null ? null : formatKg(s.declaredWeightGrams!));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _header(s),
      if (showBasePay) ...[
        const SizedBox(height: 16),
        TintCard(
          color: DropzyColors.warning,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Complete your payment',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: DropzyColors.warning)),
            if (s.baseFare.paymentExpiresAt != null) ...[
              const SizedBox(height: 4),
              Text('Pay before ${formatIst(s.baseFare.paymentExpiresAt!)} to keep your booking.',
                  style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            BusyButton(
              label: 'Pay ${formatInr(s.baseFare.totalPaise ?? 0)}',
              icon: Icons.lock_rounded,
              busy: _payingBase,
              onPressed: payBase.enabled ? () => _payBaseFare(s) : null,
            ),
            BlockerText(payBase.blockerMessage),
          ]),
        ),
      ],
      if (sc.currentQuote != null) ...[
        const SizedBox(height: 16),
        SurchargeCard(
          shipment: s,
          onPay: () => _push(SurchargePayScreen(shipmentId: s.id)),
          onDispute: () => _push(DisputeScreen(
            shipmentId: s.id,
            quoteId: sc.currentQuote!.id,
            quoteStatus: sc.currentQuote!.status,
            dcn: s.dcn,
          )),
          onEvidence: s.latestEvidenceId == null ? null : () => showWeightEvidence(context, _svc.api, s.latestEvidenceId!),
        ),
      ],
      if (s.warehousePresent || s.warehouseRequired) ...[
        const SizedBox(height: 16),
        WarehouseCard(shipment: s, onPay: () => _push(SurchargePayScreen(shipmentId: s.id))),
      ],
      if (s.pickupRequirements.isNotEmpty) ...[
        const SizedBox(height: 22),
        const SectionTitle('For pickup'),
        SoftCard(child: BulletList(s.pickupRequirements)),
      ],
      const SizedBox(height: 22),
      const SectionTitle('Parcel'),
      SoftCard(
        child: Column(children: [
          if (s.category != null) InfoRow('Category', categoryLabel(s.category!)),
          if (weight != null) InfoRow('Declared weight', weight),
          if (s.itemDescription != null) InfoRow('Contents', s.itemDescription!),
          if (s.sender?.name != null) InfoRow('Sender', s.sender!.name!),
          if (s.receiver?.name != null)
            InfoRow('Receiver', '${s.receiver!.name}${s.receiver!.phone == null ? '' : ' · ${s.receiver!.phone}'}'),
          if (s.baseFare.totalPaise != null) InfoRow('Fare', formatInr(s.baseFare.totalPaise!)),
        ]),
      ),
      const SizedBox(height: 22),
      SectionTitle('Timeline', trailing: LastSynced(s.serverTime, stale: _error != null)),
      CoreTimeline(entries: _timeline),
      const SizedBox(height: 22),
      OutlinedButton.icon(
        onPressed: () => _push(NewTicketScreen(shipmentId: s.id, dcn: s.dcn)),
        icon: const Icon(Icons.headset_mic_rounded),
        label: const Text('Get help with this shipment'),
        style: OutlinedButton.styleFrom(
          foregroundColor: DropzyColors.primary,
          side: const BorderSide(color: DropzyColors.primary),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      if (s.isAllowed('CANCEL_BOOKING')) ...[
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => _cancel(s),
          icon: const Icon(Icons.cancel_outlined, color: DropzyColors.danger),
          label: const Text('Cancel booking', style: TextStyle(color: DropzyColors.danger)),
        ),
      ],
    ]);
  }

  Widget _header(ShipmentView s) {
    final r = s.route;
    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(s.dcn ?? 'Awaiting payment',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          if (s.qrPayload != null && !prePaymentStates.contains(s.state))
            IconButton(
              tooltip: 'Show QR code',
              onPressed: () => showQrDialog(context, s.qrPayload!, s.dcn),
              icon: const Icon(Icons.qr_code_2_rounded, color: DropzyColors.primary),
            ),
        ]),
        const SizedBox(height: 8),
        ShipmentStateChip(state: s.state, label: s.stateLabel, origin: r.origin?.name, destination: r.destination?.name),
        const SizedBox(height: 12),
        Text('${r.origin?.title ?? '—'}  →  ${r.destination?.title ?? '—'}',
            style: const TextStyle(color: DropzyColors.ink, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (r.plannedDepartureAt != null) InfoRow('Departs', formatIst(r.plannedDepartureAt!)),
        if (r.plannedArrivalAt != null) InfoRow('Arrives', formatIst(r.plannedArrivalAt!)),
        if (r.operatorName != null)
          InfoRow('Bus', [r.operatorName, r.vehicleReg].whereType<String>().join(' · ')),
        if (s.serviceOption == 'WAREHOUSE_PICKUP') const InfoRow('Delivery', 'Pick up from warehouse'),
      ]),
    );
  }
}

/// C16 — confirm dialog with the tariff's cancellation policy text.
class _CancelDialog extends StatefulWidget {
  const _CancelDialog({required this.shipment, required this.services});
  final ShipmentView shipment;
  final CoreServices services;
  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  static const _reasons = ['Plans changed', 'Booked by mistake', 'Found another way to send', 'Other reason'];
  String _reason = _reasons.first;
  String? _policy;
  bool _busy = false;
  String? _error;
  final _key = ActionKey();

  @override
  void initState() {
    super.initState();
    widget.services.api.parcelPolicy().then((p) {
      final text = (p.texts.cancellation ?? '').trim().replaceAll(RegExp(r'\.+$'), '');
      if (mounted) setState(() => _policy = text.isEmpty ? 'as per the cancellation policy' : text);
    }).catchError((_) {
      if (mounted) setState(() => _policy = 'as per the cancellation policy');
    });
  }

  Future<void> _confirm() async {
    final bookingId = widget.shipment.bookingId;
    if (bookingId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final b = await _key.run((k) => widget.services.api
          .cancelBooking(bookingId, 'Cancelled by customer: $_reason', idempotencyKey: k));
      if (!mounted) return;
      final refund = b.refundPaise;
      showToast(context,
          refund == null ? 'Booking cancelled.' : 'Booking cancelled. Refund: ${refund == 0 ? 'none' : formatInr(refund)}.');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dcn = widget.shipment.dcn;
    return AlertDialog(
      title: Text(dcn == null ? 'Cancel this booking?' : 'Cancel booking $dcn?'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_policy == null ? 'Refund: loading policy…' : 'Refund: $_policy.',
              style: const TextStyle(height: 1.4)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _reason,
            decoration: const InputDecoration(labelText: 'Reason'),
            items: [for (final r in _reasons) DropdownMenuItem(value: r, child: Text(r))],
            onChanged: _busy
                ? null
                : (v) => setState(() {
                      _reason = v ?? _reason;
                      _key.reset();
                    }),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: DropzyColors.danger)),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Keep booking')),
        TextButton(
          onPressed: _busy ? null : _confirm,
          style: TextButton.styleFrom(foregroundColor: DropzyColors.danger),
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Cancel booking'),
        ),
      ],
    );
  }
}
