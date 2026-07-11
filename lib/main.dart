import 'package:baby_shophub/app_router.dart';
import 'package:baby_shophub/providers/notification_provider.dart';
import 'package:baby_shophub/utils/connectivity_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/favorites_provider.dart';
import 'services/notification_service.dart';
import 'services/navigation_service.dart';
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
          return MaterialApp.router(
            title: 'BabyShopHub',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
