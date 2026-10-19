import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'state/services.dart';
import 'state/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'screens/v2/core_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: DropzyColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // CORE_API=true → PRD v2.0 core client only (screens/v2, core_api/).
  // Otherwise the legacy demo app below runs unchanged.
  if (AppConfig.coreApi) {
    runCoreApp();
    return;
  }

  final services = Services();

  runApp(
    MultiProvider(
      providers: [
        Provider<Services>.value(value: services),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(services)..bootstrap(),
        ),
      ],
      child: const DropzyApp(),
    ),
  );
}

class DropzyApp extends StatelessWidget {
  const DropzyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dropzy',
      debugShowCheckedModeBanner: false,
      theme: buildDropzyTheme(),
      home: const _RootGate(),
    );
  }
}

/// Decides which top-level screen to show based on auth status.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    switch (auth.status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.authenticated:
        return const HomeShell();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
