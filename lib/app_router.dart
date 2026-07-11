import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/order_model.dart' as order_model;
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_orders_screen.dart';
import 'screens/admin/admin_products_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/analytics_screen.dart';
import 'screens/admin/data_export_import_screen.dart';
import 'screens/admin/reports_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/daily_spin_wheel_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/order_confirmation_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/registry_list_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/video_feed_screen.dart';
import 'services/navigation_service.dart';
import 'services/order_service.dart';
import 'services/product_service.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: NavigationService.navigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/shop', builder: (context, state) => const HomeScreen(initialIndex: 1)),
      GoRoute(path: '/cart', builder: (context, state) => const HomeScreen(initialIndex: 2)),
      GoRoute(path: '/profile', builder: (context, state) => const HomeScreen(initialIndex: 3)),
      GoRoute(path: '/orders', builder: (context, state) => const HomeScreen(initialIndex: 4)),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/checkout', builder: (context, state) => const CheckoutScreen()),
      GoRoute(path: '/payment', builder: _buildPaymentScreen),
      GoRoute(path: '/order-confirmation', builder: _buildOrderConfirmationScreen),
      GoRoute(path: '/product', builder: _buildProductScreen),
      GoRoute(path: '/product/:id', builder: _buildProductScreen),
      GoRoute(path: '/order-detail', builder: _buildOrderDetailScreen),
      GoRoute(path: '/order-detail/:orderId', builder: _buildOrderDetailScreen),
      GoRoute(path: '/order-tracking', builder: _buildOrderTrackingScreen),
      GoRoute(path: '/order-tracking/:orderId', builder: _buildOrderTrackingScreen),
      GoRoute(path: '/admin-login', builder: (context, state) => AdminLoginScreen()),
      GoRoute(path: '/admin-dashboard', builder: (context, state) => AdminDashboardScreen()),
      GoRoute(path: '/analytics', builder: (context, state) => AnalyticsScreen()),
      GoRoute(path: '/manage-products', builder: (context, state) => const EnhancedProductManagementScreen()),
      GoRoute(path: '/manage-orders', builder: (context, state) => const AdminOrdersScreen()),
      GoRoute(path: '/manage-users', builder: (context, state) => const AdminUsersScreen()),
      GoRoute(path: '/enhanced-product-management', builder: (context, state) => const EnhancedProductManagementScreen()),
      GoRoute(path: '/data-export-import', builder: (context, state) => const DataExportImportScreen()),
      GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
      GoRoute(path: '/video-feed', builder: (context, state) => const VideoFeedScreen()),
      GoRoute(path: '/spin-wheel', builder: (context, state) => const DailySpinWheelScreen()),
      GoRoute(path: '/registries', builder: (context, state) => const RegistryListScreen()),
    ],
    errorBuilder: (context, state) => const HomeScreen(),
  );

  static Widget _buildPaymentScreen(BuildContext context, GoRouterState state) {
    final extra = state.extra as Map?;
    final order = extra?['order'] as order_model.Order?;
    if (order == null) return const HomeScreen();
    return PaymentScreen(order: order);
  }

  static Widget _buildOrderConfirmationScreen(BuildContext context, GoRouterState state) {
    final extra = state.extra as Map?;
    final order = extra?['order'] as order_model.Order?;
    final transactionId = extra?['transactionId'] as String?;
    if (order == null) return const HomeScreen();
    return OrderConfirmationScreen(order: order, transactionId: transactionId);
  }

  static Widget _buildProductScreen(BuildContext context, GoRouterState state) {
    final extra = state.extra as Map?;
    final productId = state.pathParameters['id'] ?? extra?['id'] as String?;
    if (productId == null || productId.isEmpty) return const HomeScreen();
    return FutureBuilder(
      future: ProductService().getProductById(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final product = snapshot.data;
        if (product == null) return const HomeScreen();
        return ProductDetailScreen(product: product);
      },
    );
  }

  static Widget _buildOrderDetailScreen(BuildContext context, GoRouterState state) {
    final extra = state.extra as Map?;
    final orderId = state.pathParameters['orderId'] ?? extra?['orderId'] as String?;
    if (orderId == null || orderId.isEmpty) return const HomeScreen();
    return FutureBuilder(
      future: OrderService().getOrderById(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final order = snapshot.data;
        if (order == null) return const HomeScreen();
        return OrderDetailScreen(order: order);
      },
    );
  }

  static Widget _buildOrderTrackingScreen(BuildContext context, GoRouterState state) {
    final extra = state.extra as Map?;
    final order = extra?['order'] as order_model.Order?;
    if (order != null) return OrderTrackingScreen(order: order);

    final orderId = state.pathParameters['orderId'] ?? extra?['orderId'] as String?;
    if (orderId == null || orderId.isEmpty) return const HomeScreen();
    return FutureBuilder(
      future: OrderService().getOrderById(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final fetchedOrder = snapshot.data;
        if (fetchedOrder == null) return const HomeScreen();
        return OrderTrackingScreen(order: fetchedOrder);
      },
    );
  }
}