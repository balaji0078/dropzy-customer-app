import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core_api/format.dart';
import '../../core_api/labels.dart';
import '../../core_api/models.dart';
import '../../core_api/poller.dart';
import '../../widgets/common.dart';
import '../../widgets/scenery.dart';
import '../../widgets/v2/core_widgets.dart';
import '../../widgets/v2/shipment_widgets.dart';
import 'core_app.dart';
import 'shipment_detail_v2.dart';
import 'support_v2.dart';

/// C12 — booking confirmation. Polls `GET /shipments/{id}` every 10 s until
/// the server reports BOOKED; the QR stays hidden until then.
class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key, required this.shipmentId});
  final String shipmentId;
  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  late final CoreServices _svc = context.read<CoreServices>();
  ShipmentView? _s;
  Object? _error;
  late final Poller _poller = Poller(task: _load, interval: () => const Duration(seconds: 10));

  bool get _booked => _s != null && !prePaymentStates.contains(_s!.state);

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
      final s = await _svc.api.shipment(widget.shipmentId);
      if (!mounted) return;
      setState(() {
        _s = s;
        _error = null;
      });
      if (!prePaymentStates.contains(s.state) || isTerminalState(s.state)) _poller.stop();
    } catch (e) {
      if (mounted) setState(() => _error = e);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      body: RefreshIndicator(
        color: DropzyColors.primary,
        onRefresh: _poller.tick,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DropzyHero(
              title: _booked ? 'Booking confirmed' : 'Confirming your booking…',
              subtitle: _booked ? 'Your parcel is booked on the bus' : 'Waiting for the bank to confirm your payment',
              height: 180,
              overlay: IconButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: s == null
                  ? (_error != null
                      ? ErrorPanel(error: _error!, onRetry: _poller.tick, title: 'Could not load your booking')
                      : const Padding(padding: EdgeInsets.all(40), child: LoadingView()))
                  : _content(s),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(ShipmentView s) {
    final origin = s.route.origin?.name ?? 'the origin stop';
    final dep = s.route.plannedDepartureAt;
    final weight = s.declaredWeightDisplay ?? (s.declaredWeightGrams == null ? null : formatKg(s.declaredWeightGrams!));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        ShipmentStateChip(state: s.state, label: s.stateLabel, origin: s.route.origin?.name, destination: s.route.destination?.name),
        const Spacer(),
        LastSynced(s.serverTime),
      ]),
      const SizedBox(height: 16),
      if (s.dcn != null) ...[
        DcnBlock(
          dcn: s.dcn!,
          shareText: 'My Dropzy parcel ${s.dcn} — ${s.route.origin?.shortName ?? ''} → ${s.route.destination?.shortName ?? ''}',
        ),
        const SizedBox(height: 16),
      ],
      Center(
        child: _booked && s.qrPayload != null ? ShipmentQr(payload: s.qrPayload!) : const QrPendingBox(),
      ),
      const SizedBox(height: 16),
      SoftCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (dep != null)
            Text('Hand over at $origin before ${formatIst(dep.subtract(const Duration(minutes: 30)))}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.35)),
          const SizedBox(height: 10),
          InfoRow('Route', '${s.route.origin?.shortName ?? '—'} → ${s.route.destination?.shortName ?? '—'}'),
          if (dep != null) InfoRow('Bus departs', formatIst(dep)),
          if (s.route.operatorName != null) InfoRow('Operator', s.route.operatorName!),
          if (weight != null) InfoRow('Declared weight', weight),
          if (s.baseFare.totalPaise != null) InfoRow('Fare paid', formatInr(s.baseFare.totalPaise!)),
        ]),
      ),
      const SizedBox(height: 10),
      const Text('Show the QR code to the driver at handover. The driver weighs your parcel; if it is heavier '
          'than declared you will be asked to pay the difference in the app.',
          style: TextStyle(color: DropzyColors.inkSoft, fontSize: 12.5, height: 1.4)),
      const SizedBox(height: 20),
      BusyButton(
        label: 'View shipment',
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ShipmentDetailV2(shipmentId: s.id)),
        ),
      ),
      TextButton.icon(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => NewTicketScreen(shipmentId: s.id, dcn: s.dcn),
        )),
        icon: const Icon(Icons.headset_mic_rounded),
        label: const Text('Need help? Contact support'),
      ),
    ]);
  }
}
