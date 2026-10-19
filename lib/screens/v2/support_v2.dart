import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core_api/action_key.dart';
import '../../core_api/format.dart';
import '../../core_api/labels.dart';
import '../../core_api/models.dart';
import '../../core_api/poller.dart';
import '../../widgets/common.dart';
import '../../widgets/scenery.dart';
import '../../widgets/v2/core_widgets.dart';
import 'core_app.dart';

class TicketStatusChip extends StatelessWidget {
  const TicketStatusChip(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final s = ticketStatusSpec(status);
    return LabelChip(text: s.text, icon: s.icon, tone: s.tone, dense: true);
  }
}

/// C18 — support tab: my tickets + "New ticket".
class CoreSupportScreen extends StatefulWidget {
  const CoreSupportScreen({super.key, this.active = true});
  final bool active;
  @override
  State<CoreSupportScreen> createState() => _CoreSupportScreenState();
}

class _CoreSupportScreenState extends State<CoreSupportScreen> {
  late final CoreServices _svc = context.read<CoreServices>();
  List<Ticket>? _tickets;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (widget.active) _load();
  }

  @override
  void didUpdateWidget(CoreSupportScreen old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _load();
  }

  Future<void> _load() async {
    try {
      final page = await _svc.api.tickets(limit: 50);
      if (mounted) {
        setState(() {
          _tickets = page.items;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _tickets;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(const NewTicketScreen()),
        backgroundColor: DropzyColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New ticket', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: DropzyColors.primary,
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DropzyHero(title: 'Support', subtitle: 'We’re here to help, 24×7', height: 150),
            if (items == null && _error == null)
              const Padding(padding: EdgeInsets.all(40), child: LoadingView(message: 'Loading tickets...'))
            else if (items == null)
              ErrorPanel(error: _error!, onRetry: _load, title: 'Could not load tickets')
            else if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: EmptyView(
                  icon: Icons.support_agent_rounded,
                  title: 'No support tickets',
                  subtitle: 'Raise a ticket and it will show here.',
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                child: Column(children: [
                  for (final t in items) ...[
                    SoftCard(
                      onTap: () => _open(TicketDetailScreen(ticketId: t.id)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                            child: Text(t.ticketNumber ?? 'Ticket',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                          TicketStatusChip(t.status),
                        ]),
                        const SizedBox(height: 6),
                        Text(t.subject ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          [
                            ticketCategoryLabels[t.category] ?? t.category,
                            t.dcn,
                            if ((t.updatedAt ?? t.createdAt) != null) formatIst((t.updatedAt ?? t.createdAt)!),
                          ].whereType<String>().join(' • '),
                          style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 12.5),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

/// C18 — new ticket (category, subject, message, optional shipment).
class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key, this.shipmentId, this.dcn});
  final String? shipmentId;
  final String? dcn;
  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  late final CoreServices _svc = context.read<CoreServices>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  final _key = ActionKey();
  String _category = 'OTHER';
  String? _shipmentId;
  List<ShipmentSummary> _shipments = const [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _shipmentId = widget.shipmentId;
    for (final c in [_subject, _message]) {
      c.addListener(() {
        _key.reset();
        setState(() {});
      });
    }
    _svc.api.shipments(view: 'all', limit: 50).then((p) {
      if (mounted) setState(() => _shipments = p.items);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  bool get _valid => _subject.text.trim().length >= 3 && _message.text.trim().isNotEmpty;

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final t = await _key.run((k) => _svc.api.createTicket(
            category: _category,
            subject: _subject.text.trim(),
            message: _message.text.trim(),
            shipmentId: _shipmentId,
            idempotencyKey: k,
          ));
      if (!mounted) return;
      showToast(context, 'Ticket ${t.ticketNumber ?? ''} created.');
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => TicketDetailScreen(ticketId: t.id)));
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipmentItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem(value: null, child: Text('No shipment')),
      for (final s in _shipments)
        DropdownMenuItem(value: s.id, child: Text(s.dcn ?? s.routeText, overflow: TextOverflow.ellipsis)),
      if (widget.shipmentId != null && !_shipments.any((s) => s.id == widget.shipmentId))
        DropdownMenuItem(value: widget.shipmentId, child: Text(widget.dcn ?? 'This shipment')),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('New ticket')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(labelText: 'Category'),
          items: [
            for (final e in ticketCategoryLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) => setState(() {
            _category = v ?? _category;
            _key.reset();
          }),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String?>(
          initialValue: _shipmentId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Shipment (optional)'),
          items: shipmentItems,
          onChanged: (v) => setState(() {
            _shipmentId = v;
            _key.reset();
          }),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _subject,
          inputFormatters: [LengthLimitingTextInputFormatter(200)],
          decoration: const InputDecoration(labelText: 'Subject'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _message,
          minLines: 5,
          maxLines: 10,
          inputFormatters: [LengthLimitingTextInputFormatter(4000)],
          decoration: const InputDecoration(labelText: 'How can we help?', alignLabelWithHint: true),
        ),
        const SizedBox(height: 22),
        BusyButton(label: 'Send', busy: _sending, onPressed: _valid ? _send : null),
      ]),
    );
  }
}

/// C18 — ticket thread (polls every 30 s) with reply composer.
class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, required this.ticketId});
  final String ticketId;
  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late final CoreServices _svc = context.read<CoreServices>();
  final _reply = TextEditingController();
  final _key = ActionKey();
  TicketDetail? _detail;
  Object? _error;
  bool _sending = false;
  late final Poller _poller = Poller(task: _load, interval: () => const Duration(seconds: 30));

  @override
  void initState() {
    super.initState();
    _reply.addListener(() {
      _key.reset();
      setState(() {});
    });
    _poller.start();
  }

  @override
  void dispose() {
    _poller.stop();
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await _svc.api.ticket(widget.ticketId);
      if (mounted) {
        setState(() {
          _detail = d;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
      rethrow;
    }
  }

  Future<void> _send() async {
    final body = _reply.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _key.run((k) => _svc.api.addTicketMessage(widget.ticketId, body, idempotencyKey: k));
      _reply.clear();
      await _poller.tick();
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    return Scaffold(
      appBar: AppBar(title: Text(d?.ticket.ticketNumber ?? 'Ticket')),
      body: Column(children: [
        Expanded(
          child: d == null
              ? (_error != null
                  ? ErrorPanel(error: _error!, onRetry: _poller.tick)
                  : const LoadingView())
              : RefreshIndicator(
                  color: DropzyColors.primary,
                  onRefresh: _poller.tick,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    SoftCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                            child: Text(d.ticket.subject ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          ),
                          TicketStatusChip(d.ticket.status),
                        ]),
                        const SizedBox(height: 6),
                        Text(
                          [ticketCategoryLabels[d.ticket.category] ?? d.ticket.category, d.ticket.dcn]
                              .whereType<String>()
                              .join(' • '),
                          style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 12.5),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    for (final m in d.messages) _bubble(m),
                  ]),
                ),
        ),
        if (d != null && d.ticket.status != 'CLOSED')
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _reply,
                    minLines: 1,
                    maxLines: 4,
                    inputFormatters: [LengthLimitingTextInputFormatter(4000)],
                    decoration: const InputDecoration(hintText: 'Write a reply'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: (_sending || _reply.text.trim().isEmpty) ? null : _send,
                  icon: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(backgroundColor: DropzyColors.primary),
                ),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _bubble(TicketMessage m) {
    final mine = m.fromCustomer;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mine ? DropzyColors.primary.withValues(alpha: 0.18) : DropzyColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: mine ? DropzyColors.primary.withValues(alpha: 0.35) : DropzyColors.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(mine ? 'You' : (m.authorName ?? 'Dropzy support'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(m.body, style: const TextStyle(height: 1.35)),
          if (m.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(formatIst(m.createdAt!), style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 11)),
          ],
        ]),
      ),
    );
  }
}
