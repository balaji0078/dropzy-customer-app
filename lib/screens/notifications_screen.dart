import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/notification.dart';
import '../state/services.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<Services>().notifications.list();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        color: DropzyColors.primary,
        onRefresh: () async => setState(_load),
        child: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyView(
                    icon: Icons.notifications_off_outlined,
                    title: 'No notifications',
                    subtitle: "You're all caught up.",
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _tile(items[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _tile(AppNotification n) {
    final time = n.createdAt != null
        ? DateFormat('d MMM, h:mm a').format(n.createdAt!.toLocal())
        : '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: n.read ? DropzyColors.surface : DropzyColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: n.read ? DropzyColors.line : DropzyColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: DropzyColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_rounded, color: DropzyColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(n.title,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    if (!n.read)
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: DropzyColors.primary, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(n.body, style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 13)),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(time,
                      style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
