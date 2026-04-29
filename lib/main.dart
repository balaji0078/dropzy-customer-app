import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/orders/order_detail_screen.dart';
import 'screens/tracking/tracking_screen.dart';
import 'screens/estimator/estimator_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/booking/booking_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isLoading) {
              return const _LoadingScreen();
            }
            return authProvider.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen();
          },
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/orders': (context) => const OrdersScreen(),
          '/order-detail': (context) => const OrderDetailScreen(),
          '/tracking': (context) => const TrackingScreen(),
          '/estimator': (context) => const EstimatorScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/booking': (context) => const BookingScreen(),
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.redGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(51)),
                ),
                child: const Icon(Icons.local_shipping, size: 36, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Dropzy',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
