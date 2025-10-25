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
import 'providers/theme_provider.dart';
import 'services/product_service.dart';
import 'services/order_service.dart';
import 'models/order_model.dart' as order_model;
import 'screens/product_detail_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/payment_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/favorites_provider.dart';
import 'services/notification_service.dart';
import 'services/navigation_service.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/analytics_screen.dart';
import 'screens/admin/admin_products_screen.dart';
import 'screens/admin/admin_orders_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/enhanced_product_management_screen.dart';
import 'screens/admin/data_export_import_screen.dart';
import 'screens/admin/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/local_storage.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalStorage().init();

  // ✅ Initialize rich notification system with proper permissions
  final notificationService = NotificationService();
  await notificationService.initialize();
  // Print FCM token early for debugging (only in debug mode)
  assert(() {
    FirebaseMessaging.instance.getToken().then((token) {
      debugPrint('FCM TOKEN => $token');
    });
    return true;
  }());

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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => ConnectivityService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'BabyShopHub',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            themeMode: themeProvider.themeMode,
            navigatorKey: NavigationService.navigatorKey,
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/home': (context) => const HomeScreen(),
              '/order-confirmation': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map?;
                final order = args?['order'] as order_model.Order?;
                final transactionId = args?['transactionId'] as String?;
                if (order != null) {
                  return OrderConfirmationScreen(
                    order: order,
                    transactionId: transactionId,
                  );
                }
                return const HomeScreen();
              },
              '/favorites': (context) => const FavoritesScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/checkout': (context) => const CheckoutScreen(),
              '/payment': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map?;
                final order = args?['order'] as order_model.Order?;
                if (order != null) {
                  return PaymentScreen(order: order);
                }
                return const HomeScreen();
              },
              '/order-tracking': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map?;
                final order = args?['order'] as order_model.Order?;
                if (order != null) {
                  return OrderTrackingScreen(order: order);
                }
                return const HomeScreen();
              },
              '/admin-login': (context) => AdminLoginScreen(),
              '/admin-dashboard': (context) => AdminDashboardScreen(),
              '/analytics': (context) => AnalyticsScreen(),
              // Admin management routes used by drawer (map to existing screens)
              '/manage-products': (context) => const AdminProductsScreen(),
              '/manage-orders': (context) => const AdminOrdersScreen(),
              '/manage-users': (context) => const AdminUsersScreen(),
              // New admin screens
              '/enhanced-product-management': (context) =>
                  const EnhancedProductManagementScreen(),
              '/data-export-import': (context) =>
                  const DataExportImportScreen(),
              '/reports': (context) => const ReportsScreen(),
              '/order-detail': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map?;
                final orderId = args != null
                    ? args['orderId'] as String?
                    : null;
                if (orderId == null) {
                  return const HomeScreen();
                }
                return FutureBuilder(
                  future: OrderService().getOrderById(orderId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final order = snapshot.data;
                    if (order == null) {
                      return const HomeScreen();
                    }
                    return OrderDetailScreen(order: order);
                  },
                );
              },
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
                    final product = snapshot.data;
                    if (product == null) {
                      return const HomeScreen();
                    }
                    return ProductDetailScreen(product: product);
                  },
                );
              },
            },
            onUnknownRoute: (settings) =>
                MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        },
      ),
    );
  }
}
