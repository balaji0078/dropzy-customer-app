import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/shipment.dart';
import '../state/auth_provider.dart';
import '../state/services.dart';
import '../widgets/city_field.dart';
import '../widgets/common.dart';
import '../widgets/scenery.dart';
import '../widgets/status_chip.dart';
import 'booking_screen.dart';
import 'shipment_detail_screen.dart';
import 'profile_screen.dart';

/// Home tab — matches the official app: greeting, pickup/destination card,
/// quick actions, offer banner, recent shipments.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, this.onGoToTab});
  final void Function(int index)? onGoToTab;
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _pickup = TextEditingController();
  final _dest = TextEditingController();
  late Future<List<Shipment>> _recent;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _recent = context.read<Services>().shipments.list(limit: 50).catchError((_) => <Shipment>[]);
  }

  @override
  void dispose() {
    _pickup.dispose();
    _dest.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _recent;
  }

  void _book() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BookingScreen(
        prefillFrom: _pickup.text.trim(),
        prefillTo: _dest.text.trim(),
      ),
    )).then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = (user?.firstName.isNotEmpty ?? false) ? user!.firstName : 'Customer';

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: DropzyColors.primary,
          onRefresh: _refresh,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DropzyHero(
                title: 'Hi, $name 👋',
                subtitle: 'Send parcels across South India by bus',
                overlay: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    child: const Icon(Icons.person_rounded, color: Colors.white),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _weightAlert(),
                    _bookingCard(),
                    const SizedBox(height: 28),
                    const Text('Quick actions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    _quickActions(),
                    const SizedBox(height: 24),
                    _offerBanner(),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Text('Recent shipments',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => widget.onGoToTab?.call(2),
                          child: const Text('View all',
                              style: TextStyle(color: DropzyColors.primary, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _recentList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bookingCard() {
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _cityField(_pickup, Icons.my_location_rounded, 'Pickup city'),
          const Divider(height: 24),
          _cityField(_dest, Icons.place_rounded, 'Destination city'),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _book,
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Book a parcel'),
          ),
        ],
      ),
    );
  }

  Widget _cityField(TextEditingController c, IconData icon, String hint) {
    return Row(
      children: [
        Icon(icon, color: DropzyColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(child: CityField(controller: c, hint: hint, bordered: false)),
      ],
    );
  }

  Widget _quickActions() {
    final items = [
      (Icons.add_box_outlined, 'Book Parcel', _book),
      (Icons.search_rounded, 'Track', () => widget.onGoToTab?.call(1)),
      (Icons.headset_mic_rounded, 'Support', () => widget.onGoToTab?.call(3)),
      (Icons.receipt_long_rounded, 'Shipments', () => widget.onGoToTab?.call(2)),
    ];
    return Row(
      children: [
        for (final it in items)
          Expanded(child: _QuickAction(icon: it.$1, label: it.$2, onTap: it.$3)),
      ],
    );
  }

  Widget _offerBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: DropzyColors.offerGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exclusive offer',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('Save big on your first booking',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: const Text('FIRST20',
                      style: TextStyle(color: DropzyColors.primary, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          Icon(Icons.local_offer_rounded, color: Colors.white.withValues(alpha: 0.25), size: 84),
        ],
      ),
    );
  }

  Widget _recentList() {
    return FutureBuilder<List<Shipment>>(
      future: _recent,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: DropzyColors.primary)),
          );
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return SoftCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: const [
                Icon(Icons.inbox_rounded, color: DropzyColors.inkSoft, size: 34),
                SizedBox(height: 8),
                Text('No shipments yet', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Book your first parcel to see it here',
                    style: TextStyle(color: DropzyColors.inkSoft, fontSize: 12.5)),
              ],
            ),
          );
        }
        return Column(
          children: [
            for (final s in items.take(5)) ...[
              ShipmentTile(shipment: s),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  /// Prominent alert when a shipment's weight was revised up and the extra
  /// charge is still due (PRD §15.7). Opens that shipment so the user can pay.
  Widget _weightAlert() {
    return FutureBuilder<List<Shipment>>(
      future: _recent,
      builder: (context, snap) {
        final items = snap.data ?? [];
        Shipment? alert;
        for (final s in items) {
          // Show whenever there's an unpaid weight adjustment (matches the
          // tracking card). In production this naturally applies to in-transit
          // parcels once the driver revises the weight.
          if (s.weightExceeded && !s.additionalPaid && !s.isCancelled) {
            alert = s;
            break;
          }
        }
        if (alert == null) return const SizedBox.shrink();
        final s = alert;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: DropzyColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ShipmentDetailScreen(shipment: s)),
              ).then((_) => _refresh()),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DropzyColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: DropzyColors.warning.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.scale_rounded, color: DropzyColors.warning, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Weight updated',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: DropzyColors.warning)),
                          const SizedBox(height: 2),
                          Text(
                            '${s.code} • +${s.extraKg.toStringAsFixed(s.extraKg % 1 == 0 ? 0 : 1)} kg • ₹${s.additionalCharge.round()} due',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: DropzyColors.warning,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Pay ₹${s.additionalCharge.round()}',
                          style: const TextStyle(color: Color(0xFF1A1200), fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: DropzyColors.primaryTint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: DropzyColors.primary, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Shipment row — DCN code, from → to, status pill. When [detailed] is true
/// it also shows the "₹amount • weight kg" line and a chevron (Shipments tab).
class ShipmentTile extends StatelessWidget {
  const ShipmentTile({super.key, required this.shipment, this.detailed = false});
  final Shipment shipment;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ShipmentDetailScreen(shipment: shipment))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shipment.code.isEmpty ? 'Shipment' : shipment.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 6),
                Text(shipment.route,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 13.5)),
                if (detailed) ...[
                  const SizedBox(height: 6),
                  Text(
                    '₹${shipment.amount.round()} • ${shipment.weightKg.toStringAsFixed(shipment.weightKg % 1 == 0 ? 0 : 1)} kg',
                    style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(shipment.status),
              if (detailed) ...[
                const SizedBox(height: 18),
                const Icon(Icons.chevron_right_rounded, color: DropzyColors.inkSoft),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
