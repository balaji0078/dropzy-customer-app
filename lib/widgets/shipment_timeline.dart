import 'package:flutter/material.dart';
import '../core/theme.dart';

/// The fixed 7-stage lifecycle shown on the Track page, matching the app.
const List<(String, List<String>)> shipmentStages = [
  ('Booking Confirmed', ['booking_confirmed', 'booked', 'confirmed', 'pending', 'created']),
  ('Parcel Received', ['parcel_received', 'received', 'picked_up', 'pickup']),
  ('Loaded Into Bus', ['loaded_into_bus', 'loaded', 'warehouse_hold', 'in_warehouse', 'hold']),
  ('In Transit', ['in_transit', 'transit', 'out_for_delivery', 'shipped']),
  ('Arrived At Destination', ['arrived_at_destination', 'arrived']),
  ('Ready For Collection', ['ready_for_collection', 'ready']),
  ('Delivered', ['delivered', 'completed']),
];

/// Index (0-6) of the current stage for a backend status string.
int stageIndexFor(String status) {
  final s = status.toLowerCase().trim();
  for (var i = shipmentStages.length - 1; i >= 0; i--) {
    if (shipmentStages[i].$2.any((k) => s == k || s.contains(k))) return i;
  }
  return 0;
}

/// Vertical timeline card with each stage marked complete/pending.
class ShipmentTimeline extends StatelessWidget {
  const ShipmentTimeline({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final current = stageIndexFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: DropzyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DropzyColors.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < shipmentStages.length; i++)
            _row(shipmentStages[i].$1, done: i <= current, isLast: i == shipmentStages.length - 1),
        ],
      ),
    );
  }

  Widget _row(String label, {required bool done, required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? DropzyColors.primary : Colors.transparent,
                  border: Border.all(
                    color: done ? DropzyColors.primary : DropzyColors.line,
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: DropzyColors.line),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Padding(
            padding: EdgeInsets.only(top: 3, bottom: isLast ? 8 : 22),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: done ? FontWeight.w800 : FontWeight.w600,
                color: done ? DropzyColors.ink : DropzyColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
