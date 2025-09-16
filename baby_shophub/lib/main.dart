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
import 'package:awesome_notifications/awesome_notifications.dart';

import 'providers/auth_provider.dart';
import 'services/product_service.dart';
import 'models/product_model.dart';
import 'screens/product_detail_screen.dart';
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

  // Awesome Notifications init (for local/foreground notifications)
  AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'order_updates',
      channelName: 'Order Updates',
      channelDescription: 'Notifications for order status updates',
      importance: NotificationImportance.High,
      defaultColor: const Color(0xFF2196F3),
      ledColor: const Color(0xFF2196F3),
    ),
    NotificationChannel(
      channelKey: 'local_channel',
      channelName: 'Local Notifications',
      channelDescription: 'Local reminders and app events',
      importance: NotificationImportance.High,
      defaultColor: const Color(0xFF2196F3),
      ledColor: const Color(0xFF2196F3),
    ),
  ]);
  final isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

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
          // Product deep link route: expects arguments {'id': productId}
          '/product': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map?;
            final productId = args != null ? args['id'] as String? : null;
            if (productId == null) {
              return const HomeScreen();
            }
            return FutureBuilder(
              future: ProductService().getProductById(productId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final product = snapshot.data as Product?;
                if (product == null) {
                  return const HomeScreen();
                }
                return ProductDetailScreen(product: product);
              },
            );
          },
        },
      ),
    );
  }
}
