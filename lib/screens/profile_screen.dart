import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/auth_provider.dart';
import '../widgets/common.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name = (user?.firstName.trim().isNotEmpty ?? false) ? user!.firstName : 'Customer';
    final mobile = auth.mobile ?? user?.phone ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header (avatar + name + mobile) on plain background.
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: DropzyColors.primaryTint,
                  child: const Icon(Icons.person_rounded, color: DropzyColors.primary, size: 34),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(mobile.isNotEmpty ? '+91 $mobile' : (user?.email ?? ''),
                          style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _tile(context, Icons.receipt_long_rounded, 'My shipments'),
            _tile(context, Icons.account_balance_wallet_outlined, 'Payments & wallet'),
            _tile(context, Icons.description_outlined, 'Download invoices'),
            _tile(context, Icons.headset_mic_rounded, 'Help & support'),
            _tile(context, Icons.notifications_rounded, 'Notifications',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
            _tile(context, Icons.shield_outlined, 'Privacy & terms'),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DropzyColors.primary,
                side: const BorderSide(color: DropzyColors.primary),
                minimumSize: const Size.fromHeight(54),
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text('Dropzy • v1.0.0',
                  style: TextStyle(color: DropzyColors.inkSoft, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        onTap: onTap ?? () {},
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: DropzyColors.primaryTint, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: DropzyColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
            ),
            const Icon(Icons.chevron_right_rounded, color: DropzyColors.inkSoft),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You’ll need to verify your mobile number again to sign back in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: DropzyColors.primary),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}
