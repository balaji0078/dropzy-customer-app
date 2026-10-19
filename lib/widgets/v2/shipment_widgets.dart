import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../core_api/format.dart';
import '../../core_api/gates.dart';
import '../../core_api/models.dart';
import '../common.dart';
import 'core_widgets.dart';

/// High-contrast QR of the server `qr.payload` (C12/C15).
class ShipmentQr extends StatelessWidget {
  const ShipmentQr({super.key, required this.payload, this.size = 240});
  final String payload;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: QrImageView(
        data: payload,
        size: size,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
        semanticsLabel: 'Shipment QR code',
      ),
    );
  }
}

/// "Your QR code appears once payment is verified." placeholder.
class QrPendingBox extends StatelessWidget {
  const QrPendingBox({super.key});
  @override
  Widget build(BuildContext context) => Container(
        height: 200,
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DropzyColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DropzyColors.line),
        ),
        child: const Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.qr_code_2_rounded, size: 48, color: DropzyColors.inkSoft),
          SizedBox(height: 10),
          Text('Your QR code appears once payment is verified.',
              textAlign: TextAlign.center, style: TextStyle(color: DropzyColors.inkSoft)),
        ]),
      );
}

Future<void> showQrDialog(BuildContext context, String payload, String? dcn) => showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: DropzyColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(dcn ?? 'Shipment QR', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 14),
            ShipmentQr(payload: payload),
            const SizedBox(height: 12),
            const Text('Show this to the driver at handover.', style: TextStyle(color: DropzyColors.inkSoft)),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ]),
        ),
      ),
    );

/// DCN with copy / share actions.
class DcnBlock extends StatelessWidget {
  const DcnBlock({super.key, required this.dcn, this.shareText});
  final String dcn;
  final String? shareText;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(children: [
        const Icon(Icons.confirmation_number_rounded, color: DropzyColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Docket number (DCN)', style: TextStyle(color: DropzyColors.inkSoft, fontSize: 12)),
            const SizedBox(height: 2),
            SelectableText(dcn, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
        ),
        IconButton(
          tooltip: 'Copy DCN',
          icon: const Icon(Icons.copy_rounded),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: dcn));
            showToast(context, 'DCN copied');
          },
        ),
        IconButton(
          tooltip: 'Share DCN',
          icon: const Icon(Icons.share_rounded),
          onPressed: () async {
            final text = shareText ?? 'Track my Dropzy parcel: $dcn';
            final ok = await launchUrl(Uri.parse('sms:?body=${Uri.encodeComponent(text)}'),
                mode: LaunchMode.externalApplication);
            if (!ok) {
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) showToast(context, 'Copied to share');
            }
          },
        ),
      ]),
    );
  }
}

/// C14 / C4 tile.
class CoreShipmentTile extends StatelessWidget {
  const CoreShipmentTile({super.key, required this.shipment, required this.onTap});
  final ShipmentSummary shipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = shipment;
    return SoftCard(
      onTap: onTap,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.dcn ?? 'Booking — awaiting payment',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 6),
            Text(s.routeText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 13.5)),
            if (s.plannedDepartureAt != null) ...[
              const SizedBox(height: 4),
              Text('Departs ${formatIst(s.plannedDepartureAt!)}',
                  style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 12.5)),
            ],
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              ShipmentStateChip(
                state: s.state,
                label: s.stateLabel,
                origin: s.origin?.name,
                destination: s.destination?.name,
                dense: true,
              ),
              if (s.amountDuePaise > 0) AmountDueChip(paise: s.amountDuePaise),
            ]),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded, color: DropzyColors.inkSoft),
      ]),
    );
  }
}

IconData _timelineIcon(String kind) {
  switch (kind) {
    case 'PAYMENT':
      return Icons.payments_rounded;
    case 'WEIGHT':
      return Icons.scale_rounded;
    case 'QUOTE':
      return Icons.request_quote_rounded;
    case 'HOLD':
      return Icons.lock_rounded;
    case 'CUSTODY':
      return Icons.handshake_rounded;
    case 'NOTIFICATION':
      return Icons.notifications_rounded;
    case 'DISPUTE':
      return Icons.gavel_rounded;
    default:
      return Icons.local_shipping_rounded;
  }
}

/// Server timeline (oldest first) — no local stages.
class CoreTimeline extends StatelessWidget {
  const CoreTimeline({super.key, required this.entries});
  final List<TimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SoftCard(
        child: Text('No updates yet.', style: TextStyle(color: DropzyColors.inkSoft)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: DropzyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DropzyColors.line),
      ),
      child: Column(children: [
        for (var i = 0; i < entries.length; i++)
          _row(entries[i], latest: i == entries.length - 1, isLast: i == entries.length - 1),
      ]),
    );
  }

  Widget _row(TimelineEntry e, {required bool latest, required bool isLast}) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: latest ? DropzyColors.primary : DropzyColors.primaryTint,
            ),
            child: Icon(_timelineIcon(e.kind), size: 16, color: latest ? Colors.white : DropzyColors.primary),
          ),
          if (!isLast) Expanded(child: Container(width: 2, color: DropzyColors.line)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4, bottom: isLast ? 6 : 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.title,
                  style: TextStyle(
                      fontWeight: latest ? FontWeight.w800 : FontWeight.w600,
                      color: latest ? DropzyColors.ink : DropzyColors.ink.withValues(alpha: 0.85))),
              if (e.detail != null && e.detail!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(e.detail!, style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 13, height: 1.35)),
              ],
              if (e.at != null) ...[
                const SizedBox(height: 3),
                Text(formatIst(e.at!), style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 11.5)),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

/// §6.3 warehouse card.
class WarehouseCard extends StatelessWidget {
  const WarehouseCard({super.key, required this.shipment, this.onPay});
  final ShipmentView shipment;
  final VoidCallback? onPay;

  Future<void> _directions(BuildContext context) async {
    final w = shipment.warehouseInfo;
    final query = (w?.latitude != null && w?.longitude != null)
        ? '${w!.latitude},${w.longitude}'
        : [w?.name, w?.address].whereType<String>().join(', ');
    if (query.isEmpty) return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showToast(context, 'Could not open maps.');
  }

  @override
  Widget build(BuildContext context) {
    final copy = warehouseCardCopy(shipment);
    if (copy == null) return const SizedBox.shrink();
    final unpaid = shipment.state == 'WAREHOUSE_HOLD_UNPAID';
    final color = unpaid
        ? DropzyColors.danger
        : (shipment.state == 'READY_FOR_PICKUP' ? DropzyColors.success : DropzyColors.primary);
    final payGate = gateFor(shipment, 'PAY_SURCHARGE');
    return TintCard(
      color: color,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.warehouse_rounded, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(copy.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(copy.body, style: const TextStyle(height: 1.4, fontSize: 13.5)),
        if (shipment.warehouseInfo?.phone != null) ...[
          const SizedBox(height: 6),
          Text('Phone: ${shipment.warehouseInfo!.phone}', style: const TextStyle(color: DropzyColors.inkSoft)),
        ],
        const SizedBox(height: 12),
        if (unpaid && copy.payAmount != null && onPay != null) ...[
          BusyButton(
            label: 'Pay ${copy.payAmount}',
            icon: Icons.lock_rounded,
            color: DropzyColors.warning,
            onPressed: payGate.enabled ? onPay : null,
          ),
          BlockerText(payGate.blockerMessage),
          const SizedBox(height: 8),
        ],
        if (copy.directions)
          OutlinedButton.icon(
            onPressed: () => _directions(context),
            icon: const Icon(Icons.directions_rounded),
            label: const Text('Get directions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DropzyColors.ink,
              side: const BorderSide(color: DropzyColors.line),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
      ]),
    );
  }
}
