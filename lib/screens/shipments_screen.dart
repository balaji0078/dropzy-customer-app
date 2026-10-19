import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/shipment.dart';
import '../state/services.dart';
import '../widgets/common.dart';
import '../widgets/scenery.dart';
import 'home_tab.dart' show ShipmentTile;

/// "My shipments" with Active / Delivered / Cancelled tabs — matches the app.
class ShipmentsScreen extends StatefulWidget {
  const ShipmentsScreen({super.key});
  @override
  State<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen> {
  late Future<List<Shipment>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = context.read<Services>().shipments.list(limit: 100);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(children: [
          const DropzyHero(
              title: 'My shipments',
              subtitle: 'All your parcels in one place',
              height: 150,
              showBus: true),
          Material(
            color: DropzyColors.bg,
            child: const TabBar(
              labelColor: DropzyColors.primary,
              unselectedLabelColor: DropzyColors.inkSoft,
              indicatorColor: DropzyColors.primary,
              labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              tabs: [Tab(text: 'Active'), Tab(text: 'Delivered'), Tab(text: 'Cancelled')],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Shipment>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Loading your shipments...');
            }
            if (snap.hasError) {
              return EmptyView(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load shipments',
                subtitle: snap.error.toString().replaceFirst('Exception: ', ''),
                onRetry: () => setState(_load),
              );
            }
            final all = snap.data ?? [];
            return TabBarView(
              children: [
                _list(all.where((s) => s.isActive).toList(), 'active'),
                _list(all.where((s) => s.isDelivered).toList(), 'delivered'),
                _list(all.where((s) => s.isCancelled).toList(), 'cancelled'),
              ],
            );
          },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _list(List<Shipment> items, String kind) {
    if (items.isEmpty) {
      return RefreshIndicator(
        color: DropzyColors.primary,
        onRefresh: () async => setState(_load),
        child: ListView(
          children: [
            const SizedBox(height: 100),
            EmptyView(
              icon: Icons.inbox_rounded,
              title: 'No $kind shipments',
              subtitle: 'Shipments will appear here.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: DropzyColors.primary,
      onRefresh: () async => setState(_load),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => ShipmentTile(shipment: items[i], detailed: true),
      ),
    );
  }
}
