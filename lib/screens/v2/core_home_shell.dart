import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import 'core_app.dart';
import 'core_home_tab.dart';
import 'core_profile_screen.dart';
import 'core_shipments_screen.dart';
import 'core_track_screen.dart';
import 'support_v2.dart';

/// Authenticated shell (CORE_API) — same 5 tabs as the legacy app:
/// Home · Track · Shipments · Support · Profile. Hidden tabs pause polling.
class CoreHomeShell extends StatefulWidget {
  const CoreHomeShell({super.key});
  @override
  State<CoreHomeShell> createState() => _CoreHomeShellState();
}

class _CoreHomeShellState extends State<CoreHomeShell> {
  int _index = 0;
  late final CoreServices _svc = context.read<CoreServices>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _svc.links.setReady(true));
  }

  @override
  void dispose() {
    _svc.links.setReady(false);
    super.dispose();
  }

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      CoreHomeTab(active: _index == 0, onGoToTab: _go),
      const CoreTrackScreen(),
      CoreShipmentsScreen(active: _index == 2),
      CoreSupportScreen(active: _index == 3),
      CoreProfileScreen(active: _index == 4),
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
                color: states.contains(WidgetState.selected) ? DropzyColors.primary : DropzyColors.inkSoft,
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
