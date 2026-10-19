import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/token_store.dart';
import '../../core_api/api.dart';
import '../../core_api/payment_coordinator.dart';
import '../../core_api/session.dart';
import '../../navigation/deep_link_router.dart';
import 'core_auth_screens.dart';
import 'core_home_shell.dart';

/// Everything the CORE_API screens need, provided once at the root.
class CoreServices {
  CoreServices({required this.api, required this.payments, required this.links});
  final CoreApi api;
  final PaymentCoordinator payments;
  final DeepLinkRouter links;
  ApiClient get client => api.client;
}

/// Entry point for `--dart-define=CORE_API=true` builds.
Future<void> runCoreApp() async {
  final deviceId = await DeviceIdentity.load();
  final tokens = SecureTokenStore();
  final client = ApiClient(coreMode: true, tokenStore: tokens, deviceId: deviceId);
  final api = CoreApi(client);
  final session = CoreSession(api: api, tokens: tokens, deviceId: deviceId);
  final payments = PaymentCoordinator();
  final navigatorKey = GlobalKey<NavigatorState>();
  final links = DeepLinkRouter(navigatorKey: navigatorKey, payments: payments);
  final services = CoreServices(api: api, payments: payments, links: links);

  runApp(MultiProvider(
    providers: [
      Provider<CoreServices>.value(value: services),
      ChangeNotifierProvider<CoreSession>.value(value: session),
    ],
    child: CoreApp(navigatorKey: navigatorKey),
  ));

  unawaited(session.bootstrap());
  // Cold-start link + every later link (duplicates of the initial link that
  // the stream may replay are ignored by the router).
  final appLinks = AppLinks();
  links.listen(appLinks.uriLinkStream);
  try {
    final initial = await appLinks.getInitialLink();
    if (initial != null) links.handleUri(initial);
  } catch (_) {/* no initial link */}
}

class CoreApp extends StatelessWidget {
  const CoreApp({super.key, required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dropzy',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildDropzyTheme(),
      home: _CoreRootGate(navigatorKey: navigatorKey),
    );
  }
}

class _CoreRootGate extends StatefulWidget {
  const _CoreRootGate({required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;
  @override
  State<_CoreRootGate> createState() => _CoreRootGateState();
}

class _CoreRootGateState extends State<_CoreRootGate> {
  late final CoreSession _session = context.read<CoreSession>();
  CoreAuthStatus _last = CoreAuthStatus.unknown;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSession);
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    super.dispose();
  }

  void _onSession() {
    // Session ended / logged out while deep in the stack → back to the root
    // so the login screen is visible.
    if (_last == CoreAuthStatus.authenticated && _session.status == CoreAuthStatus.unauthenticated) {
      widget.navigatorKey.currentState?.popUntil((r) => r.isFirst);
    }
    _last = _session.status;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CoreSession>();
    switch (session.status) {
      case CoreAuthStatus.unknown:
        return const CoreSplashScreen();
      case CoreAuthStatus.unauthenticated:
        return const CoreLoginScreen();
      case CoreAuthStatus.authenticated:
        return session.needsName ? const NamePromptScreen() : const CoreHomeShell();
    }
  }
}
