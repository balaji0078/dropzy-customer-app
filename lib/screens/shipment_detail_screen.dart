import 'package:flutter/material.dart';

import '../models/shipment.dart';
import '../widgets/shipment_tracking_view.dart';

/// Tapping a shipment shows the same tracking view (result card + timeline +
/// Simulate next update) as the Track tab.
class ShipmentDetailScreen extends StatelessWidget {
  const ShipmentDetailScreen({super.key, required this.shipment});
  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(shipment.code.isEmpty ? 'Shipment' : shipment.code)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ShipmentTrackingView(shipment: shipment),
        ],
      ),
    );
  }
}
