import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/shipment.dart';
import '../state/services.dart';
import 'shipment_timeline.dart';
import 'status_chip.dart';

/// Result card + "Shipment timeline" + "Simulate next update" — the exact
/// layout the official app shows for a tracked shipment. Reused by the Track
/// tab and the shipment detail screen.
class ShipmentTrackingView extends StatefulWidget {
  const ShipmentTrackingView({super.key, required this.shipment});
  final Shipment shipment;

  @override
  State<ShipmentTrackingView> createState() => _ShipmentTrackingViewState();
}

class _ShipmentTrackingViewState extends State<ShipmentTrackingView> {
  late Shipment _shipment = widget.shipment;
  bool _advancing = false;
  bool _payingExtra = false;
  bool _extraPaidLocally = false;
  Timer? _poll;

  bool get _needsExtraPayment =>
      _shipment.weightExceeded && !_shipment.additionalPaid && !_extraPaidLocally;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void didUpdateWidget(ShipmentTrackingView old) {
    super.didUpdateWidget(old);
    if (old.shipment.id != widget.shipment.id) {
      _shipment = widget.shipment;
      _startPolling();
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// Live updates: re-fetch the shipment every 5s until it's delivered.
  void _startPolling() {
    _poll?.cancel();
    if (_delivered) return;
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    try {
      final latest = await context.read<Services>().shipments.refresh(_shipment.id, _shipment.code);
      if (latest != null && mounted && latest.status != _shipment.status) {
        setState(() => _shipment = latest);
        if (_delivered) _poll?.cancel();
      }
    } catch (_) {/* keep last known state; try again next tick */}
  }

  Future<void> _simulate() async {
    if (_advancing) return;
    setState(() => _advancing = true);
    try {
      final updated = await context.read<Services>().shipments.advance(_shipment.id);
      setState(() => _shipment = updated.code.isEmpty ? _shipment.copyWith(status: updated.status) : updated);
      _startPolling();
    } catch (_) {
      // Fallback: advance locally through the fixed lifecycle.
      final next = stageIndexFor(_shipment.status) + 1;
      if (next < shipmentStages.length) {
        setState(() => _shipment = _shipment.copyWith(status: shipmentStages[next].$2.first));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shipment already delivered.')),
        );
      }
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  Future<void> _payAdditional() async {
    if (_payingExtra) return;
    setState(() => _payingExtra = true);
    final amount = _shipment.additionalCharge;
    try {
      final updated =
          await context.read<Services>().shipments.payAdditional(_shipment.id, amount);
      if (updated != null && updated.id.isNotEmpty) {
        setState(() => _shipment = updated);
      } else {
        // Backend endpoint unavailable — settle locally for the demo.
        setState(() => _extraPaidLocally = true);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paid ₹${amount.round()} additional charge.')),
        );
      }
      _startPolling();
    } catch (_) {
      setState(() => _extraPaidLocally = true);
    } finally {
      if (mounted) setState(() => _payingExtra = false);
    }
  }

  bool get _delivered => stageIndexFor(_shipment.status) >= shipmentStages.length - 1;

  @override
  Widget build(BuildContext context) {
    final s = _shipment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Result card ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: DropzyColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DropzyColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(s.code.isEmpty ? 'Shipment' : s.code,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(s.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(s.route, style: const TextStyle(fontSize: 15, color: DropzyColors.inkSoft)),
              const SizedBox(height: 6),
              Text('Operator: ${s.operatorName?.isNotEmpty == true ? s.operatorName : 'Auto-allocated'}',
                  style: const TextStyle(color: DropzyColors.inkSoft)),
              const SizedBox(height: 4),
              Text(
                'Weight: ${s.weightKg.toStringAsFixed(s.weightKg % 1 == 0 ? 0 : 1)} kg  •  Fare: ₹${s.amount.round()}',
                style: const TextStyle(color: DropzyColors.inkSoft),
              ),
            ],
          ),
        ),

        // ── Weight discrepancy → additional payment (§15.7) ──
        if (_needsExtraPayment) ...[
          const SizedBox(height: 16),
          _weightDiscrepancyCard(s),
        ],
        // ── Warehouse hold (unpaid on arrival) ──
        if (s.isWarehouseHold && _needsExtraPayment) ...[
          const SizedBox(height: 12),
          _warehouseHoldCard(),
        ],

        const SizedBox(height: 24),
        Row(
          children: [
            const Text('Shipment timeline',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const Spacer(),
            if (!_delivered) const _LiveBadge(),
          ],
        ),
        const SizedBox(height: 14),
        ShipmentTimeline(status: s.status),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: (_advancing || _delivered) ? null : _simulate,
          icon: _advancing
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: DropzyColors.primary))
              : const Icon(Icons.keyboard_double_arrow_right_rounded),
          label: Text(_delivered ? 'Delivered' : 'Simulate next update'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DropzyColors.primary,
            side: const BorderSide(color: DropzyColors.primary),
            minimumSize: const Size.fromHeight(54),
          ),
        ),
      ],
    );
  }

  Widget _weightDiscrepancyCard(Shipment s) {
    String kg(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DropzyColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DropzyColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.scale_rounded, color: DropzyColors.warning, size: 22),
              SizedBox(width: 8),
              Text('Weight updated by driver',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: DropzyColors.warning)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Declared ${kg(s.declaredKg)} kg → Actual ${kg(s.actualKg)} kg  (+${kg(s.extraKg)} kg)',
              style: const TextStyle(color: DropzyColors.ink, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Additional charge: ₹${s.additionalCharge.round()}',
              style: const TextStyle(color: DropzyColors.warning, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Pay before your parcel reaches the destination, or it will be held at the warehouse and the receiver won’t be able to collect it.',
            style: TextStyle(color: DropzyColors.inkSoft, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _payingExtra ? null : _payAdditional,
            icon: _payingExtra
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                : const Icon(Icons.account_balance_wallet_rounded),
            label: Text(_payingExtra ? 'Processing…' : 'Pay ₹${s.additionalCharge.round()} now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DropzyColors.warning,
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _warehouseHoldCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DropzyColors.primaryTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DropzyColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.warehouse_rounded, color: DropzyColors.primary, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Held at warehouse — the receiver can’t collect this parcel until the additional charge above is paid.',
              style: TextStyle(color: DropzyColors.ink, fontSize: 13, height: 1.35, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small pulsing "Live" pill shown while the timeline auto-refreshes.
class _LiveBadge extends StatefulWidget {
  const _LiveBadge();
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DropzyColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _c,
            child: Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: DropzyColors.success, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 6),
          const Text('Live',
              style: TextStyle(color: DropzyColors.success, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
