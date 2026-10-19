import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/support_ticket.dart';
import '../state/services.dart';
import '../widgets/common.dart';
import '../widgets/scenery.dart';
import '../widgets/status_chip.dart';

/// Support tickets list — matches the official app (TKT cards + New ticket).
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late Future<List<SupportTicket>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = context.read<Services>().support.tickets();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Raise a ticket — help@dropzy.in')),
        ),
        backgroundColor: DropzyColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New ticket', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: Column(children: [
          const DropzyHero(
              title: 'Support',
              subtitle: 'We’re here to help, 24×7',
              height: 150),
          Expanded(
            child: RefreshIndicator(
          color: DropzyColors.primary,
          onRefresh: () async => setState(_load),
          child: FutureBuilder<List<SupportTicket>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const LoadingView(message: 'Loading tickets...');
              }
              final items = snap.data ?? [];
              if (snap.hasError || items.isEmpty) {
                return ListView(
                  children: [
                    const SizedBox(height: 100),
                    EmptyView(
                      icon: snap.hasError ? Icons.cloud_off_rounded : Icons.support_agent_rounded,
                      title: snap.hasError ? 'Could not load tickets' : 'No support tickets',
                      subtitle: snap.hasError
                          ? snap.error.toString().replaceFirst('Exception: ', '')
                          : 'Raise a ticket and it will show here.',
                      onRetry: snap.hasError ? () => setState(_load) : null,
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _ticketCard(items[i]),
              );
            },
          ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _ticketCard(SupportTicket t) {
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(t.id, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              StatusChip(t.status),
            ],
          ),
          const SizedBox(height: 10),
          Text('${t.category} • ${t.dcn}',
              style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Priority: ${t.priority}',
              style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 14)),
        ],
      ),
    );
  }
}
