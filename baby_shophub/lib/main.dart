import 'package:baby_shophub/providers/notification_provider.dart';
import 'package:baby_shophub/screens/auth/forgot_password_screen.dart';
import 'package:baby_shophub/screens/auth/login_screen.dart';
import 'package:baby_shophub/screens/auth/register_screen.dart';
import 'package:baby_shophub/screens/home_screen.dart';
import 'package:baby_shophub/screens/order_confirmation_screen.dart';
import 'package:baby_shophub/screens/favorites_screen.dart';
import 'package:baby_shophub/utils/connectivity_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/favorites_provider.dart';
import 'services/notification_service.dart';
import 'services/navigation_service.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/analytics_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'utils/local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocalStorage().init();

  // ✅ Only initialize notifications (don’t send test ones here)
  final notificationService = NotificationService();
  await notificationService.initialize();
  // Print FCM token early for debugging
  try {
    final token = await FirebaseMessaging.instance.getToken();
    // ignore: avoid_print
    print('FCM TOKEN => $token');
  } catch (_) {}

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        Provider(create: (_) => ConnectivityService()),
      ],
      child: MaterialApp(
        title: 'BabyShopHub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: NavigationService.navigatorKey,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const HomeScreen(),
          '/order-confirmation': (context) => const OrderConfirmationScreen(),
          '/favorites': (context) => const FavoritesScreen(),
          '/admin-login': (context) => AdminLoginScreen(),
          '/admin-dashboard': (context) => AdminDashboardScreen(),
          '/analytics': (context) => AnalyticsScreen(),
        },
      ),
    );
  }
}
