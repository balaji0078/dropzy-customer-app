import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Colored pill for a shipment/ticket status — translucent tint over the dark
/// surface so it reads well in the dark theme.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    late Color fg;
    if (s.contains('deliver')) {
      fg = DropzyColors.success;
    } else if (s.contains('cancel') || s.contains('fail') || s.contains('return')) {
      fg = DropzyColors.danger;
    } else if (s.contains('hold') || s.contains('warehouse') || s == 'open') {
      fg = DropzyColors.warning;
    } else {
      // in transit, ready for collection, booked, investigating, assigned…
      fg = DropzyColors.info;
    }

    // Sentence case, e.g. "warehouse_hold" -> "Warehouse hold".
    final words = status.replaceAll('_', ' ').trim();
    final label = words.isEmpty
        ? words
        : '${words[0].toUpperCase()}${words.substring(1).toLowerCase()}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(color: fg, fontSize: 12.5, fontWeight: FontWeight.w700)),
    );
  }
}
