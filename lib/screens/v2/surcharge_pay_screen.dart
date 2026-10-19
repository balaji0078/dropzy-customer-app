import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core_api/action_key.dart';
import '../../core_api/api.dart';
import '../../core_api/labels.dart';
import '../../core_api/models.dart';
import '../../core_api/payment_coordinator.dart';
import '../../core_api/poller.dart';
import '../../widgets/common.dart';
import '../../widgets/scenery.dart';
import '../../widgets/v2/core_widgets.dart';
import '../../widgets/v2/surcharge_card.dart';
import 'core_app.dart';
import 'dispute_screen.dart';
import 'payment_flow_screen.dart';

/// "See weight evidence": signed URL of the scale photo (`GET /evidence/{id}`).
Future<void> showWeightEvidence(BuildContext context, CoreApi api, String evidenceId) async {
  try {
    final ev = await api.evidence(evidenceId);
    final url = ev.downloadUrl;
    if (url == null || !context.mounted) return;
    final full = url.startsWith('http') ? url : '${AppConfig.apiOrigin}$url';
    if ((ev.contentType ?? 'image/').startsWith('image/')) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: DropzyColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Weight evidence', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  full,
                  fit: BoxFit.contain,
                  loadingBuilder: (c, child, p) =>
                      p == null ? child : const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                  errorBuilder: (c, e, st) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Could not load the photo.', style: TextStyle(color: DropzyColors.inkSoft)),
                  ),
                ),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ]),
          ),
        ),
      );
    } else {
      await launchUrl(Uri.parse(full), mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    if (context.mounted) showApiError(context, e);
  }
}

/// C11 — surcharge pay sheet. Polls every 10 s while open.
class SurchargePayScreen extends StatefulWidget {
  const SurchargePayScreen({super.key, required this.shipmentId});
  final String shipmentId;
  @override
  State<SurchargePayScreen> createState() => _SurchargePayScreenState();
}

class _SurchargePayScreenState extends State<SurchargePayScreen> {
  late final CoreServices _svc = context.read<CoreServices>();
  ShipmentView? _shipment;
  SurchargeStatus? _surcharge;
  Object? _error;
  bool _paying = false;
  bool _acknowledging = false;
  final _payKey = ActionKey();
  final _ackKey = ActionKey();
  late final Poller _poller = Poller(task: _load, interval: () => const Duration(seconds: 10));

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
        _svc.api.currentSurcharge(widget.shipmentId),
      ]);
      if (!mounted) return;
      setState(() {
        _shipment = results[0] as ShipmentView;
        _surcharge = results[1] as SurchargeStatus;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
      rethrow;
    }
  }

  Future<void> _acknowledge(SurchargeQuote q) async {
    await _ackKey.run((k) => _svc.api.acknowledgeSurcharge(widget.shipmentId, q.id, idempotencyKey: k));
  }

  Future<void> _onAcknowledge() async {
    final q = _surcharge?.currentQuote;
    if (q == null) return;
    setState(() => _acknowledging = true);
    try {
      await _acknowledge(q);
      await _poller.tick();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _acknowledging = false);
    }
  }

  /// accept (acknowledge, if not yet) → POST /payments/intents → checkout → verifying.
  Future<void> _pay() async {
    final sc = _surcharge;
    final invoiceId = sc?.payableInvoiceId;
    if (sc == null || invoiceId == null) return;
    setState(() => _paying = true);
    try {
      final q = sc.currentQuote;
      if (q != null && q.customerAcknowledgedAt == null) {
        try {
          await _acknowledge(q);
        } catch (_) {/* acknowledgement is not required to pay */}
      }
      final intent = await _payKey.run((k) => _svc.api.createPaymentIntent(invoiceId, idempotencyKey: k));
      if (!mounted) return;
      await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => PaymentFlowScreen.checkout(
          intent: intent,
          purpose: PaymentPurpose.surcharge,
          shipmentId: widget.shipmentId,
        ),
      ));
      if (mounted) await _poller.tick();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _dispute() async {
    final q = _surcharge?.currentQuote;
    if (q == null) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DisputeScreen(shipmentId: widget.shipmentId, quoteId: q.id, quoteStatus: q.status, dcn: _shipment?.dcn),
    ));
    if (mounted) await _poller.tick();
  }

  @override
  Widget build(BuildContext context) {
    final s = _shipment;
    final sc = _surcharge;
    return Scaffold(
      body: RefreshIndicator(
        color: DropzyColors.primary,
        onRefresh: _poller.tick,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DropzyHero(
              title: 'Extra weight charge',
              subtitle: s?.dcn ?? 'Your parcel',
              height: 160,
              overlay: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: (s == null || sc == null)
                  ? (_error != null
                      ? ErrorPanel(error: _error!, onRetry: _poller.tick, title: 'Could not load the charge')
                      : const Padding(padding: EdgeInsets.all(40), child: LoadingView()))
                  : _content(s, sc),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(ShipmentView s, SurchargeStatus sc) {
    final q = sc.currentQuote;
    if (q == null || sc.customerLabel == 'NONE') {
      return const EmptyView(
        icon: Icons.check_circle_outline_rounded,
        title: 'No extra charge',
        subtitle: 'There is no extra weight charge on this parcel.',
      );
    }
    final intent = sc.latestIntent;
    final verifying = sc.customerLabel == 'VERIFYING';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(alignment: Alignment.centerRight, child: LastSynced(s.serverTime, stale: _error != null)),
      const SizedBox(height: 8),
      if (verifying) ...[
        TintCard(
          color: DropzyColors.info,
          child: const Row(children: [
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: DropzyColors.info)),
            SizedBox(width: 12),
            Expanded(
              child: Text('Verifying your payment with the bank… This can take up to a minute. Do not pay again.',
                  style: TextStyle(fontWeight: FontWeight.w700, height: 1.35)),
            ),
          ]),
        ),
        if (intent != null && intentPendingStatuses.contains(intent.status))
          TextButton(
            onPressed: () async {
              await Navigator.of(context).push<bool>(MaterialPageRoute(
                builder: (_) => PaymentFlowScreen.verifying(
                    intentId: intent.id, purpose: PaymentPurpose.surcharge, shipmentId: s.id),
              ));
              if (mounted) await _poller.tick();
            },
            child: const Text('View payment status'),
          ),
        const SizedBox(height: 12),
      ],
      SurchargeCard(
        shipment: s,
        surcharge: sc,
        paying: _paying,
        onPay: _pay,
        onDispute: _dispute,
        onEvidence: s.latestEvidenceId == null ? null : () => showWeightEvidence(context, _svc.api, s.latestEvidenceId!),
      ),
      if (q.status == 'OPEN' && q.customerAcknowledgedAt == null && !surchargeNoPayLabels.contains(sc.customerLabel)) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _acknowledging ? null : _onAcknowledge,
          icon: const Icon(Icons.task_alt_rounded),
          label: const Text('I understand'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DropzyColors.ink,
            side: const BorderSide(color: DropzyColors.line),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
      const SizedBox(height: 10),
      const Text(
        'Pay only in the Dropzy app. Cash and screenshots cannot be accepted.',
        style: TextStyle(color: DropzyColors.inkSoft, fontSize: 12.5, height: 1.4),
      ),
    ]);
  }
}
