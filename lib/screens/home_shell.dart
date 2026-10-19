import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'home_tab.dart';
import 'track_screen.dart';
import 'shipments_screen.dart';
import 'support_screen.dart';
import 'profile_screen.dart';

/// Authenticated shell — 5-tab bottom nav matching the official app:
/// Home · Track · Shipments · Support · Profile.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(onGoToTab: _go),
      const TrackScreen(),
      const ShipmentsScreen(),
      const SupportScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: DropzyColors.surface,
          indicatorColor: DropzyColors.primaryTint,
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: states.contains(WidgetState.selected)
                    ? DropzyColors.primary
                    : DropzyColors.inkSoft,
              )),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _go,
          height: 66,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined, color: DropzyColors.inkSoft),
                selectedIcon: Icon(Icons.home_rounded, color: DropzyColors.primary),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.search_rounded, color: DropzyColors.inkSoft),
                selectedIcon: Icon(Icons.search_rounded, color: DropzyColors.primary),
                label: 'Track'),
            NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined, color: DropzyColors.inkSoft),
                selectedIcon: Icon(Icons.receipt_long_rounded, color: DropzyColors.primary),
                label: 'Shipments'),
            NavigationDestination(
                icon: Icon(Icons.headset_mic_outlined, color: DropzyColors.inkSoft),
                selectedIcon: Icon(Icons.headset_mic_rounded, color: DropzyColors.primary),
                label: 'Support'),
            NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, color: DropzyColors.inkSoft),
                selectedIcon: Icon(Icons.person_rounded, color: DropzyColors.primary),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
