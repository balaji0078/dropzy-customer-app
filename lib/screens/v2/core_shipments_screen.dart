import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core_api/models.dart';
import '../../core_api/poller.dart';
import '../../widgets/common.dart';
import '../../widgets/scenery.dart';
import '../../widgets/v2/core_widgets.dart';
import '../../widgets/v2/shipment_widgets.dart';
import 'core_app.dart';
import 'shipment_detail_v2.dart';

/// C14 — Active / Delivered / Cancelled (`GET /shipments?view=`). Loads on
/// open, pull-to-refresh, and polls the visible tab every 30 s.
class CoreShipmentsScreen extends StatefulWidget {
  const CoreShipmentsScreen({super.key, this.active = true});
  final bool active;
  @override
  State<CoreShipmentsScreen> createState() => _CoreShipmentsScreenState();
}

class _CoreShipmentsScreenState extends State<CoreShipmentsScreen> with SingleTickerProviderStateMixin {
  static const _views = ['active', 'delivered', 'cancelled'];
  late final CoreServices _svc = context.read<CoreServices>();
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final Map<String, List<ShipmentSummary>> _data = {};
  final Map<String, Object?> _errors = {};
  late final Poller _poller = Poller(task: _load, interval: () => const Duration(seconds: 30));

  String get _view => _views[_tabs.index];

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _poller.tick();
    });
    if (widget.active) _poller.start();
  }

  @override
  void didUpdateWidget(CoreShipmentsScreen old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _poller.start();
    if (!widget.active && old.active) _poller.stop();
  }

  @override
  void dispose() {
    _poller.stop();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final view = _view;
    try {
      final page = await _svc.api.shipments(view: view, limit: 50);
      if (!mounted) return;
      setState(() {
        _data[view] = page.items;
        _errors[view] = null;
      });
    } catch (e) {
      if (mounted) setState(() => _errors[view] = e);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        const DropzyHero(title: 'My shipments', subtitle: 'All your parcels in one place', height: 150),
        Material(
          color: DropzyColors.bg,
          child: TabBar(
            controller: _tabs,
            labelColor: DropzyColors.primary,
            unselectedLabelColor: DropzyColors.inkSoft,
            indicatorColor: DropzyColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            tabs: const [Tab(text: 'Active'), Tab(text: 'Delivered'), Tab(text: 'Cancelled')],
          ),
        ),
        Expanded(
          child: TabBarView(controller: _tabs, children: [for (final v in _views) _list(v)]),
        ),
      ]),
    );
  }

  Widget _list(String view) {
    final items = _data[view];
    final error = _errors[view];
    Widget body;
    if (items == null) {
      body = ListView(children: [
        const SizedBox(height: 60),
        error != null
            ? ErrorPanel(error: error, onRetry: _poller.tick, title: 'Could not load shipments')
            : const LoadingView(message: 'Loading your shipments...'),
      ]);
    } else if (items.isEmpty) {
      body = ListView(children: [
        const SizedBox(height: 80),
        EmptyView(icon: Icons.inbox_rounded, title: 'No $view shipments', subtitle: 'Shipments will appear here.'),
      ]);
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => CoreShipmentTile(
          shipment: items[i],
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ShipmentDetailV2(shipmentId: items[i].id)),
            );
            if (mounted) await _poller.tick();
          },
        ),
      );
    }
    return RefreshIndicator(color: DropzyColors.primary, onRefresh: _poller.tick, child: body);
  }
}
