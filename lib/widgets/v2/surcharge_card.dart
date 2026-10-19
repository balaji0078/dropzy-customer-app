import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core_api/format.dart';
import '../../core_api/gates.dart';
import '../../core_api/models.dart';
import 'core_widgets.dart';

/// CLIENT_CONTRACTS.md §6.1 breakdown — every number comes from the server
/// `breakdown` (amounts from its `lines`, weights from `display`/grams).
class SurchargeBreakdownTable extends StatelessWidget {
  const SurchargeBreakdownTable({super.key, required this.quote});
  final SurchargeQuote quote;

  @override
  Widget build(BuildContext context) {
    final b = quote.breakdown;
    final d = b.display;
    String kg(String key, int? grams, {bool signed = false}) =>
        d[key] ?? (grams == null ? '—' : (signed ? formatSignedKg(grams) : formatKg(grams)));
    final surchargeLine = b.line('SURCHARGE');
    final fee = b.line('FEE');
    final tax = b.line('TAX');
    final units = b.extraUnits;
    final inc = b.incrementGrams;
    final rate = b.ratePerIncrementPaise;
    final billable = kg('billableDifference', b.billableDifferenceGrams);
    final total = d['total'] ?? formatInr(b.totalPaise ?? quote.totalPaise);
    final tariff = b.tariffVersion ?? quote.tariffVersion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Extra weight charge', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 8),
        InfoRow('Declared weight', kg('declared', b.declaredWeightGrams)),
        InfoRow('Measured weight', kg('actual', b.actualWeightGrams)),
        InfoRow('Difference', kg('rawDifference', b.rawDifferenceGrams, signed: true)),
        if (b.toleranceGrams != null) InfoRow('Allowed variance', formatGrams(b.toleranceGrams!)),
        InfoRow('Billable extra weight',
            (units != null && inc != null) ? '$billable ($units × ${formatGrams(inc)})' : billable),
        InfoRow(
          (units != null && rate != null) ? 'Extra weight ($units × ${formatInr(rate)})' : 'Extra weight',
          formatInr(surchargeLine?.amountPaise ?? 0),
        ),
        if (fee != null) InfoRow(fee.label.isEmpty ? 'Surcharge handling fee' : fee.label, formatInr(fee.amountPaise)),
        if (tax != null)
          InfoRow(quote.taxRateBps == null ? 'GST' : 'GST ${formatBpsPercent(quote.taxRateBps!)}',
              formatInr(tax.amountPaise)),
        const Divider(height: 18),
        InfoRow('Total due', total, emphasize: true),
        const SizedBox(height: 4),
        Text(
          [
            if (tariff != null) 'Tariff version $tariff',
            if (quote.version != null) 'Quote v${quote.version}',
          ].join(' · '),
          style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 12),
        ),
      ],
    );
  }
}

/// §6.2 deadline lines (ticks every second for the countdown).
class SurchargeDeadline extends StatelessWidget {
  const SurchargeDeadline({super.key, required this.shipment, required this.surcharge, this.now});
  final ShipmentView shipment;
  final SurchargeStatus surcharge;

  /// Fixed clock for tests; null → live ticking.
  final DateTime? now;

  Widget _lines(DateTime t) {
    final lines = surchargeDeadlineCopy(shipment, surcharge, t);
    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final l in lines) ...[
          Text(l.headline,
              style: const TextStyle(fontWeight: FontWeight.w800, color: DropzyColors.ink, fontSize: 14.5)),
          if (l.body != null) ...[
            const SizedBox(height: 3),
            Text(l.body!, style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 13, height: 1.35)),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (now != null) return _lines(now!);
    return Ticker(builder: (_, t) => _lines(t));
  }
}

/// Surcharge card for C15 (and the body of the C11 sheet).
class SurchargeCard extends StatelessWidget {
  const SurchargeCard({
    super.key,
    required this.shipment,
    this.surcharge,
    this.onPay,
    this.onDispute,
    this.onEvidence,
    this.paying = false,
    this.now,
  });

  final ShipmentView shipment;

  /// Fresher `/surcharge-quotes/current` result; defaults to `shipment.surcharge`.
  final SurchargeStatus? surcharge;
  final VoidCallback? onPay;
  final VoidCallback? onDispute;
  final VoidCallback? onEvidence;
  final bool paying;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final sc = surcharge ?? shipment.surcharge;
    final quote = sc.currentQuote;
    final settled = sc.customerLabel == 'PAID' || sc.customerLabel == 'WAIVED';
    final color = settled ? DropzyColors.success : DropzyColors.warning;
    final payGate = surchargePayGate(shipment, sc);
    final disputeGate = gateFor(shipment, 'OPEN_DISPUTE');

    return TintCard(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.scale_rounded, color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Weight checked by driver',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
            ),
            SurchargeLabelChip(code: sc.customerLabel, dense: true),
          ]),
          const SizedBox(height: 12),
          if (quote != null) SurchargeBreakdownTable(quote: quote),
          const SizedBox(height: 12),
          SurchargeDeadline(shipment: shipment, surcharge: sc, now: now),
          Text(surchargeWhyCopy, style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 12.5, height: 1.4)),
          const SizedBox(height: 4),
          Wrap(spacing: 4, children: [
            if (onEvidence != null && shipment.latestEvidenceId != null)
              TextButton.icon(
                onPressed: onEvidence,
                icon: const Icon(Icons.photo_outlined, size: 18),
                label: const Text('See weight evidence'),
              ),
            if (onDispute != null)
              TextButton.icon(
                onPressed: disputeGate.enabled ? onDispute : null,
                icon: const Icon(Icons.gavel_rounded, size: 18),
                label: const Text('Dispute this charge'),
              ),
          ]),
          if (onDispute != null && !disputeGate.enabled) BlockerText(disputeGate.blockerMessage),
          if (onPay != null && !settled) ...[
            const SizedBox(height: 8),
            BusyButton(
              label: 'Pay ${surchargeAmountText(sc)}',
              icon: Icons.lock_rounded,
              busy: paying,
              color: DropzyColors.warning,
              onPressed: payGate.enabled ? onPay : null,
            ),
            BlockerText(payGate.blockerMessage),
          ],
        ],
      ),
    );
  }
}
