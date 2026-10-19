import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core_api/action_key.dart';
import '../../core_api/format.dart';
import '../../core_api/models.dart';
import '../../core_api/session.dart';
import '../../widgets/common.dart';
import '../../widgets/v2/core_widgets.dart';
import 'core_app.dart';
import 'notifications_v2.dart';

/// C19 — profile: name (PATCH /me), phone, active sessions, logout.
class CoreProfileScreen extends StatefulWidget {
  const CoreProfileScreen({super.key, this.active = true});
  final bool active;
  @override
  State<CoreProfileScreen> createState() => _CoreProfileScreenState();
}

class _CoreProfileScreenState extends State<CoreProfileScreen> {
  late final CoreServices _svc = context.read<CoreServices>();
  List<SessionInfo>? _sessions;
  Object? _sessionsError;
  final Set<String> _revoking = {};

  @override
  void initState() {
    super.initState();
    if (widget.active) _load();
  }

  @override
  void didUpdateWidget(CoreProfileScreen old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _load();
  }

  Future<void> _load() async {
    final session = context.read<CoreSession>();
    try {
      await session.reloadMe();
    } catch (_) {/* keep cached profile */}
    try {
      final s = await _svc.api.sessions();
      if (mounted) {
        setState(() {
          _sessions = s;
          _sessionsError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _sessionsError = e);
    }
  }

  Future<void> _editName(Me? me) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _NameDialog(initial: me?.name ?? '', services: _svc),
    );
    if (saved == true && mounted) showToast(context, 'Name updated.');
  }

  Future<void> _revoke(SessionInfo s) async {
    setState(() => _revoking.add(s.id));
    try {
      await _svc.api.revokeSession(s.id, idempotencyKey: newIdempotencyKey());
      await _load();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _revoking.remove(s.id));
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You’ll need to verify your mobile number again to sign back in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok == true && mounted) await context.read<CoreSession>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<CoreSession>().me;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), automaticallyImplyLeading: false),
      body: RefreshIndicator(
        color: DropzyColors.primary,
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Row(children: [
            const CircleAvatar(
              radius: 34,
              backgroundColor: DropzyColors.primaryTint,
              child: Icon(Icons.person_rounded, color: DropzyColors.primary, size: 34),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(me?.displayName ?? 'Customer', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(me?.phone ?? '', style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 14)),
              ]),
            ),
            IconButton(
              tooltip: 'Edit name',
              onPressed: () => _editName(me),
              icon: const Icon(Icons.edit_rounded, color: DropzyColors.primary),
            ),
          ]),
          const SizedBox(height: 24),
          SoftCard(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoreNotificationsScreen())),
            child: const Row(children: [
              Icon(Icons.notifications_rounded, color: DropzyColors.primary),
              SizedBox(width: 14),
              Expanded(child: Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5))),
              Icon(Icons.chevron_right_rounded, color: DropzyColors.inkSoft),
            ]),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Signed-in devices'),
          if (_sessions == null && _sessionsError == null)
            const Padding(padding: EdgeInsets.all(20), child: LoadingView())
          else if (_sessions == null)
            ErrorPanel(error: _sessionsError!, onRetry: _load, title: 'Could not load devices')
          else
            for (final s in _sessions!) ...[
              SoftCard(
                child: Row(children: [
                  Icon(s.devicePlatform == 'ios' ? Icons.phone_iphone_rounded : Icons.phone_android_rounded,
                      color: DropzyColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.deviceName ?? s.appVariant ?? 'Device',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        s.current
                            ? 'This device'
                            : 'Last active ${s.lastUsedAt == null ? '—' : formatIst(s.lastUsedAt!)}',
                        style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 12.5),
                      ),
                    ]),
                  ),
                  if (!s.current)
                    TextButton(
                      onPressed: _revoking.contains(s.id) ? null : () => _revoke(s),
                      child: const Text('Sign out'),
                    ),
                ]),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DropzyColors.primary,
              side: const BorderSide(color: DropzyColors.primary),
              minimumSize: const Size.fromHeight(54),
            ),
          ),
          const SizedBox(height: 18),
          const Center(child: Text('Dropzy • v1.0.0', style: TextStyle(color: DropzyColors.inkSoft, fontSize: 12))),
        ]),
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial, required this.services});
  final String initial;
  final CoreServices services;
  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _c = TextEditingController(text: widget.initial);
  final _key = ActionKey();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      _key.reset();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = context.read<CoreSession>();
    try {
      final me = await _key.run((k) => widget.services.api.updateMe(name: _c.text.trim(), idempotencyKey: k));
      session.setMe(me);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: _c,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [LengthLimitingTextInputFormatter(120)],
          decoration: InputDecoration(hintText: 'Full name', errorText: _error),
        ),
        actions: [
          TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: (_busy || _c.text.trim().isEmpty) ? null : _save,
            child: const Text('Save'),
          ),
        ],
      );
}
