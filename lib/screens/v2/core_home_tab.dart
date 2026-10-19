import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core_api/gates.dart';
import '../../core_api/models.dart';
import '../../core_api/poller.dart';
import '../../core_api/session.dart';
import '../../widgets/common.dart';
import '../../widgets/scenery.dart';
import '../../widgets/v2/core_widgets.dart';
import '../../widgets/v2/shipment_widgets.dart';
import 'booking_v2.dart';
import 'core_app.dart';
import 'notifications_v2.dart';
import 'shipment_detail_v2.dart';
import 'surcharge_pay_screen.dart';

/// C4 — home: "Send a parcel", surcharge-due banners, active shipments,
/// unread badge. Polls every 30 s while visible and in the foreground.
class CoreHomeTab extends StatefulWidget {
  const CoreHomeTab({super.key, this.active = true, this.onGoToTab});
  final bool active;
  final void Function(int index)? onGoToTab;
  @override
  State<CoreHomeTab> createState() => _CoreHomeTabState();
}

class _CoreHomeTabState extends State<CoreHomeTab> {
  late final CoreServices _svc = context.read<CoreServices>();
  List<ShipmentSummary>? _active;
  int _unread = 0;
  Object? _error;
  late final Poller _poller = Poller(task: _load, interval: () => const Duration(seconds: 30));

  @override
  void initState() {
    super.initState();
    if (widget.active) _poller.start();
  }

  @override
  void didUpdateWidget(CoreHomeTab old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _poller.start();
    if (!widget.active && old.active) _poller.stop();
  }

  @override
  void dispose() {
    _poller.stop();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _svc.api.shipments(view: 'active', limit: 5),
        _svc.api.unreadCount(),
      ]);
      if (!mounted) return;
      setState(() {
        _active = (results[0] as Paged<ShipmentSummary>).items;
        _unread = results[1] as int;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
      rethrow;
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) await _poller.tick();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<CoreSession>().me;
    final due = (_active ?? const <ShipmentSummary>[]).where((s) => s.surchargeDue).toList();
    return Scaffold(
      body: RefreshIndicator(
        color: DropzyColors.primary,
        onRefresh: _poller.tick,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DropzyHero(
              title: 'Send a parcel',
              subtitle: 'Hi ${me?.firstName ?? 'there'} — by bus across South India',
              overlay: _Bell(unread: _unread, onTap: () => _open(const CoreNotificationsScreen())),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final s in due) ...[
                  _SurchargeBanner(shipment: s, onTap: () => _open(SurchargePayScreen(shipmentId: s.id))),
                  const SizedBox(height: 12),
                ],
                SoftCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('Where is your parcel going?',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Pick a bus, declare the weight, pay securely in the app.',
                        style: TextStyle(color: DropzyColors.inkSoft, fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _open(const CoreBookingScreen()),
                      icon: const Icon(Icons.add_box_outlined),
                      label: const Text('Book a parcel'),
                    ),
                  ]),
                ),
                const SizedBox(height: 26),
                const Text('Quick actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Row(children: [
                  _QuickAction(icon: Icons.add_box_outlined, label: 'Book Parcel', onTap: () => _open(const CoreBookingScreen())),
                  _QuickAction(icon: Icons.search_rounded, label: 'Track', onTap: () => widget.onGoToTab?.call(1)),
                  _QuickAction(icon: Icons.headset_mic_rounded, label: 'Support', onTap: () => widget.onGoToTab?.call(3)),
                  _QuickAction(icon: Icons.receipt_long_rounded, label: 'Shipments', onTap: () => widget.onGoToTab?.call(2)),
                ]),
                const SizedBox(height: 28),
                SectionTitle('Active shipments',
                    trailing: GestureDetector(
                      onTap: () => widget.onGoToTab?.call(2),
                      child: const Text('View all',
                          style: TextStyle(color: DropzyColors.primary, fontWeight: FontWeight.w700)),
                    )),
                _list(),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    final items = _active;
    if (items == null) {
      return _error != null
          ? ErrorPanel(error: _error!, onRetry: _poller.tick, title: 'Could not load shipments')
          : const Padding(padding: EdgeInsets.all(24), child: LoadingView());
    }
    if (items.isEmpty) {
      return const SoftCard(
        padding: EdgeInsets.all(22),
        child: Column(children: [
          Icon(Icons.inbox_rounded, color: DropzyColors.inkSoft, size: 34),
          SizedBox(height: 8),
          Text('No active shipments', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 2),
          Text('Book a parcel to see it here', style: TextStyle(color: DropzyColors.inkSoft, fontSize: 12.5)),
        ]),
      );
    }
    return Column(children: [
      for (final s in items) ...[
        CoreShipmentTile(shipment: s, onTap: () => _open(ShipmentDetailV2(shipmentId: s.id))),
        const SizedBox(height: 12),
      ],
    ]);
  }
}

class _SurchargeBanner extends StatelessWidget {
  const _SurchargeBanner({required this.shipment, required this.onTap});
  final ShipmentSummary shipment;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: TintCard(
          color: DropzyColors.warning,
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DropzyColors.warning.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.scale_rounded, color: DropzyColors.warning, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(surchargeBannerText(shipment),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, height: 1.35)),
            ),
            const Icon(Icons.chevron_right_rounded, color: DropzyColors.warning),
          ]),
        ),
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.unread, required this.onTap});
  final int unread;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: unread > 0 ? '$unread unread notifications' : 'Notifications',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Badge(
          isLabelVisible: unread > 0,
          label: Text(unread > 99 ? '99+' : '$unread'),
          backgroundColor: DropzyColors.danger,
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            child: const Icon(Icons.notifications_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: DropzyColors.primaryTint, borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, color: DropzyColors.primary, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
