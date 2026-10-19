import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/error_copy.dart';
import '../../core/theme.dart';
import '../../core_api/format.dart';
import '../../core_api/labels.dart';

/// Pill with icon + text (colour is never the only indicator, §1.10).
class LabelChip extends StatelessWidget {
  const LabelChip({super.key, required this.text, required this.icon, required this.tone, this.dense = false});
  final String text;
  final IconData icon;
  final ChipTone tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final fg = toneColor(tone);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 4 : 6),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 13 : 15, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: fg, fontSize: dense ? 11.5 : 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Shipment `stateLabel` chip (§2.4).
class ShipmentStateChip extends StatelessWidget {
  const ShipmentStateChip({super.key, required this.state, this.label, this.origin, this.destination, this.dense = false});
  final String state;
  final String? label;
  final String? origin;
  final String? destination;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final spec = stateSpec(state);
    return LabelChip(
      text: stateLabelText(state, label, originStop: origin, destinationStop: destination),
      icon: spec.icon,
      tone: spec.tone,
      dense: dense,
    );
  }
}

/// `surcharge.customerLabel` chip (§2.5); hidden for NONE.
class SurchargeLabelChip extends StatelessWidget {
  const SurchargeLabelChip({super.key, required this.code, this.dense = false});
  final String? code;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final spec = surchargeLabelSpec(code);
    if (spec == null) return const SizedBox.shrink();
    return LabelChip(text: spec.text, icon: spec.icon, tone: spec.tone, dense: dense);
  }
}

class AmountDueChip extends StatelessWidget {
  const AmountDueChip({super.key, required this.paise});
  final int paise;
  @override
  Widget build(BuildContext context) => LabelChip(
        text: '${formatInr(paise)} due',
        icon: Icons.account_balance_wallet_rounded,
        tone: ChipTone.warning,
        dense: true,
      );
}

/// Two-column money / weight row.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.emphasize = false, this.color});
  final String label;
  final String value;
  final bool emphasize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: color ?? (emphasize ? DropzyColors.ink : DropzyColors.inkSoft),
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
      fontSize: emphasize ? 15.5 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(value, style: style.copyWith(color: color ?? DropzyColors.ink), textAlign: TextAlign.right),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Tinted surface (warning / danger / info cards) — same recipe as the
/// legacy weight-discrepancy card.
class TintCard extends StatelessWidget {
  const TintCard({super.key, required this.color, required this.child, this.padding});
  final Color color;
  final Widget child;
  final EdgeInsets? padding;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: child,
      );
}

/// Blocker message shown under a disabled button (§1.7).
class BlockerText extends StatelessWidget {
  const BlockerText(this.message, {super.key});
  final String? message;
  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded, size: 16, color: DropzyColors.warning),
        const SizedBox(width: 6),
        Expanded(
          child: Text(message!, style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 12.5, height: 1.35)),
        ),
      ]),
    );
  }
}

/// Primary button with a busy spinner.
class BusyButton extends StatelessWidget {
  const BusyButton({super.key, required this.label, required this.onPressed, this.busy = false, this.icon, this.color});
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ]);
    return ElevatedButton(
      onPressed: busy ? null : onPressed,
      style: color == null ? null : ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: const Color(0xFF1A1200)),
      child: child,
    );
  }
}

/// "Last synced 03:35 PM" from the server's `serverTime` (§1.9).
class LastSynced extends StatelessWidget {
  const LastSynced(this.serverTime, {super.key, this.stale = false});
  final DateTime? serverTime;
  final bool stale;
  @override
  Widget build(BuildContext context) {
    if (serverTime == null) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(stale ? Icons.cloud_off_rounded : Icons.sync_rounded,
          size: 14, color: stale ? DropzyColors.warning : DropzyColors.inkSoft),
      const SizedBox(width: 4),
      Text('Last synced ${formatIstClock(serverTime!)}',
          style: TextStyle(fontSize: 12, color: stale ? DropzyColors.warning : DropzyColors.inkSoft)),
    ]);
  }
}

/// Rebuilds [builder] every second so countdowns stay current.
class Ticker extends StatefulWidget {
  const Ticker({super.key, required this.builder, this.period = const Duration(seconds: 1)});
  final Widget Function(BuildContext context, DateTime now) builder;
  final Duration period;
  @override
  State<Ticker> createState() => _TickerState();
}

class _TickerState extends State<Ticker> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(widget.period, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.now());
}

/// SnackBar with the §6 copy; "Details" reveals code + correlationId.
void showApiError(BuildContext context, Object error) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final e = error is ApiException ? error : null;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(e?.message ?? ErrorCopy.generic),
    action: (e?.correlationId != null || e?.code != null)
        ? SnackBarAction(
            label: 'Details',
            textColor: DropzyColors.primary,
            onPressed: () => showErrorDetails(context, e!),
          )
        : null,
  ));
}

void showToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(SnackBar(content: Text(message)));
}

Future<void> showErrorDetails(BuildContext context, ApiException e) {
  final text = [
    if (e.code != null) 'Code: ${e.code}',
    if (e.correlationId != null) 'Reference: ${e.correlationId}',
    if (e.statusCode > 0) 'HTTP ${e.statusCode}',
  ].join('\n');
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Error details'),
      content: SelectableText(text.isEmpty ? e.message : text),
      actions: [
        if (e.correlationId != null)
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: e.correlationId!));
              Navigator.pop(ctx);
            },
            child: const Text('Copy reference'),
          ),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
      ],
    ),
  );
}

/// Full-area error with retry; long-press shows the correlation id.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.error, this.onRetry, this.title = 'Something went wrong'});
  final Object error;
  final VoidCallback? onRetry;
  final String title;

  @override
  Widget build(BuildContext context) {
    final e = error is ApiException ? error as ApiException : null;
    return GestureDetector(
      onLongPress: e == null ? null : () => showErrorDetails(context, e),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: DropzyColors.primaryTint, shape: BoxShape.circle),
            child: Icon(e?.isNetwork == true ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
                color: DropzyColors.primary, size: 30),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          Text(e?.message ?? ErrorCopy.generic,
              textAlign: TextAlign.center, style: const TextStyle(color: DropzyColors.inkSoft, height: 1.4)),
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DropzyColors.primary,
                side: const BorderSide(color: DropzyColors.primary),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Bulleted list (pickup requirements).
class BulletList extends StatelessWidget {
  const BulletList(this.items, {super.key});
  final List<String> items;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final i in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_circle_outline_rounded, size: 16, color: DropzyColors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(i, style: const TextStyle(height: 1.35))),
              ]),
            ),
        ],
      );
}
