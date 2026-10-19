import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core_api/action_key.dart';
import '../../core_api/deep_links.dart';
import '../../core_api/format.dart';
import '../../core_api/models.dart';
import '../../widgets/common.dart';
import '../../widgets/v2/core_widgets.dart';
import 'core_app.dart';

IconData _iconFor(String? template) {
  switch (template) {
    case 'SURCHARGE_DUE':
    case 'DEADLINE_APPROACHING':
    case 'DEADLINE_EXTENDED':
    case 'SURCHARGE_REVISED':
      return Icons.scale_rounded;
    case 'TRIP_CANCELLED':
    case 'TRIP_DELAYED':
    case 'TRIP_CHANGED':
    case 'NOT_LOADED_AT_DEPARTURE':
      return Icons.directions_bus_rounded;
    case 'CUTOFF_MISSED':
    case 'WAREHOUSE_RECEIVED':
    case 'WAREHOUSE_HOLD_UPDATED':
    case 'READY_FOR_PICKUP':
    case 'MAX_HOLD_REMINDER':
    case 'WAREHOUSE_DIVERSION':
      return Icons.warehouse_rounded;
    case 'SURCHARGE_PAID':
    case 'BOOKING_CONFIRMED':
    case 'SURCHARGE_WAIVED':
      return Icons.check_circle_rounded;
    case 'PAYMENT_FAILED':
    case 'BOOKING_EXPIRED':
    case 'REJECTED_AT_ORIGIN':
      return Icons.error_outline_rounded;
    case 'DISPUTE_OPENED':
    case 'DISPUTE_RESOLVED':
      return Icons.gavel_rounded;
    case 'REFUND_ISSUED':
    case 'BOOKING_CANCELLED':
    case 'BOOKING_CANCELLED_REFUND':
      return Icons.undo_rounded;
    case 'DELIVERED':
    case 'PICKED_UP':
      return Icons.done_all_rounded;
    default:
      return Icons.local_shipping_rounded;
  }
}

/// C17 — in-app notifications; tap opens `data.screen` (surchargePay → C11,
/// shipment → C15) and marks it read.
class CoreNotificationsScreen extends StatefulWidget {
  const CoreNotificationsScreen({super.key});
  @override
  State<CoreNotificationsScreen> createState() => _CoreNotificationsScreenState();
}

class _CoreNotificationsScreenState extends State<CoreNotificationsScreen> {
  late final CoreServices _svc = context.read<CoreServices>();
  final List<CoreNotification> _items = [];
  PageMeta _meta = const PageMeta();
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  final Set<String> _readLocally = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final p = await _svc.api.notifications(page: 1, limit: 20);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(p.items);
        _meta = p.meta;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _more() async {
    if (_loadingMore || !_meta.hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final p = await _svc.api.notifications(page: _meta.page + 1, limit: 20);
      if (mounted) {
        setState(() {
          _items.addAll(p.items);
          _meta = p.meta;
        });
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _readAll() async {
    try {
      await _svc.api.markAllNotificationsRead(idempotencyKey: newIdempotencyKey());
      await _load();
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  void _tap(CoreNotification n) {
    if (!n.isRead && !_readLocally.contains(n.id)) {
      setState(() => _readLocally.add(n.id));
      _svc.api.markNotificationRead(n.id, idempotencyKey: newIdempotencyKey()).catchError((_) {});
    }
    final link = deepLinkFromNotification(n.data, fallbackShipmentId: n.shipmentId);
    if (link != null) _svc.links.open(link);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [TextButton(onPressed: _items.isEmpty ? null : _readAll, child: const Text('Mark all read'))],
      ),
      body: RefreshIndicator(
        color: DropzyColors.primary,
        onRefresh: _load,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView();
    if (_error != null && _items.isEmpty) {
      return ListView(children: [const SizedBox(height: 80), ErrorPanel(error: _error!, onRetry: _load)]);
    }
    if (_items.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 120),
        EmptyView(icon: Icons.notifications_off_outlined, title: 'No notifications', subtitle: "You're all caught up."),
      ]);
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (sn) {
        if (sn.metrics.pixels > sn.metrics.maxScrollExtent - 200) _more();
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + (_meta.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i >= _items.length) {
            return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
          }
          return _tile(_items[i]);
        },
      ),
    );
  }

  Widget _tile(CoreNotification n) {
    final read = n.isRead || _readLocally.contains(n.id);
    return Material(
      color: read ? DropzyColors.surface : DropzyColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _tap(n),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: read ? DropzyColors.line : DropzyColors.primary.withValues(alpha: 0.35)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DropzyColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconFor(n.templateCode), color: DropzyColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800))),
                  if (!read)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Text('New', style: TextStyle(color: DropzyColors.primary, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                ]),
                const SizedBox(height: 4),
                Text(n.body, style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 13, height: 1.35)),
                if (n.createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(formatIst(n.createdAt!), style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 11)),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
