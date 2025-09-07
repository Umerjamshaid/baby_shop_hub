import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // Get token
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap when app is in foreground
        _handleNotificationTap(details);
      },
    );

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Handle messages when app is in background (opened via tap)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    // Handle initial message when app is launched from terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  /// 🔹 Background handler
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
    _showNotification(message);
  }

  /// 🔹 Show notification
  static Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'order_updates',
      'Order Updates',
      channelDescription: 'Notifications for order status updates',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      message.notification?.title ?? 'BabyShopHub',
      message.notification?.body ?? 'New notification',
      platformChannelSpecifics,
      payload: message.data['type'] ?? 'general',
    );
  }

  /// 🔹 Handle message opened app
  static void _handleMessage(RemoteMessage message) {
    print("Message opened app: ${message.messageId}");
    final String type = message.data['type'] ?? 'general';
    _handleNotificationType(type, message.data);
  }

  /// 🔹 Handle notification tap
  static void _handleNotificationTap(NotificationResponse response) {
    final String type = response.payload ?? 'general';
    _handleNotificationType(type, {});
  }

  /// 🔹 Handle notification type logic
  static void _handleNotificationType(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'order_update':
        print('Order update notification tapped');
        break;
      case 'new_arrival':
        print('New arrival notification tapped');
        break;
      case 'offer':
        print('Offer notification tapped');
        break;
      case 'cart_reminder':
        print('Cart reminder notification tapped');
        break;
      default:
        print('General notification tapped');
        break;
    }
  }

  /// 🔹 Subscribe/unsubscribe to generic topics
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  /// 🔹 User-specific order updates
  static Future<void> subscribeToOrderUpdates(String userId) async {
    await _firebaseMessaging.subscribeToTopic('order_$userId');
    print('Subscribed to order updates for user: $userId');
  }

  static Future<void> unsubscribeFromOrderUpdates(String userId) async {
    await _firebaseMessaging.unsubscribeFromTopic('order_$userId');
    print('Unsubscribed from order updates for user: $userId');
  }

  /// 🔹 Admin-only order notifications
  static Future<void> subscribeAdminToOrders() async {
    await _firebaseMessaging.subscribeToTopic('admin_orders');
    print('✅ Subscribed to admin_orders topic');
  }

  static Future<void> unsubscribeAdminFromOrders() async {
    await _firebaseMessaging.unsubscribeFromTopic('admin_orders');
    print('🚫 Unsubscribed from admin_orders topic');
  }

  /// 🔹 Local-only notifications (cart abandonment, etc.)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'local_channel',
      'Local Notifications',
      channelDescription: 'This channel is used for local notifications.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}
