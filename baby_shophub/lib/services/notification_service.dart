import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notification_model.dart';
import '../utils/constants.dart';
import 'navigation_service.dart';

// Top-level background handler required by Firebase Messaging
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Keep lightweight; actual navigation happens when app resumes
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<String>? _tokenSubscription; // 🔹 store listener

  // -------------------- 🔹 INITIALIZATION --------------------
  Future<void> initializeNotifications() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted permission');
    }

    String? token = await _firebaseMessaging.getToken();
    print("📲 FCM Token: $token");

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _handleNotificationTap(details);
      },
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Ensure Android notification channel exists for heads-up notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'order_updates',
      'Order Updates',
      description: 'Notifications for order status updates',
      importance: Importance.high,
      playSound: true,
    );
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(channel);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  // -------------------- 🔹 FCM TOKEN MANAGEMENT --------------------
  Future<void> saveTokenToFirestore(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .update({
              'fcmTokens': FieldValue.arrayUnion([token]),
              'updatedAt': DateTime.now().toIso8601String(),
            });
        print('✅ Token saved for user: $userId');
      }
    } catch (e) {
      print('❌ Failed to save token: $e');
    }
  }

  void listenForTokenChanges(String userId) {
    _tokenSubscription = _firebaseMessaging.onTokenRefresh.listen((
      newToken,
    ) async {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'fcmTokens': FieldValue.arrayUnion([newToken]),
            'updatedAt': DateTime.now().toIso8601String(),
          });
      print('🔄 Token refreshed for user: $userId');
    });
  }

  void cancelTokenListener() {
    _tokenSubscription?.cancel();
    _tokenSubscription = null;
    print("🛑 Token listener cancelled");
  }

  // -------------------- 🔹 FIRESTORE NOTIFICATION STORAGE --------------------
  Future<void> sendNotificationToUsers({
    required String title,
    required String message,
    required List<String> userIds,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        userIds: userIds,
        imageUrl: imageUrl,
        data: data,
        sentAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notification.id)
          .set(notification.toMap());

      print('📩 Notification saved: $title');
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }

  Future<void> sendNotificationToAll({
    required String title,
    required String message,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      final usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .get();
      final userIds = usersSnapshot.docs.map((doc) => doc.id).toList();

      await sendNotificationToUsers(
        title: title,
        message: message,
        userIds: userIds,
        imageUrl: imageUrl,
        data: data,
      );
    } catch (e) {
      throw Exception('Failed to send notification to all users: $e');
    }
  }

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userIds', arrayContains: userId)
          .orderBy('sentAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                NotificationModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user notifications: $e');
    }
  }

  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .update({
            'readBy': FieldValue.arrayUnion([userId]),
          });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // -------------------- 🔹 FCM HANDLERS --------------------
  // Background handled by top-level function

  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'order_updates',
          'Order Updates',
          channelDescription: 'Notifications for order status updates',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      message.notification?.title ?? 'BabyShopHub',
      message.notification?.body ?? 'New notification',
      platformDetails,
      payload: message.data['type'] ?? 'general',
    );
  }

  void _handleMessage(RemoteMessage message) {
    final String type = message.data['type'] ?? 'general';
    _handleNotificationType(type, message.data);
  }

  void _handleNotificationTap(NotificationResponse response) {
    final String type = response.payload ?? 'general';
    _handleNotificationType(type, {});
  }

  void _handleNotificationType(String type, Map<String, dynamic> data) {
    // Minimal navigation mapping using a global navigator key
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    switch (type) {
      case 'order_update':
        navigator.pushNamed('/order-confirmation');
        return;
      case 'new_arrival':
      case 'offer':
      case 'cart_reminder':
      case 'general':
      default:
        navigator.pushNamed('/home');
        return;
    }
  }

  // -------------------- 🔹 TOPICS --------------------
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print("✅ Subscribed to topic: $topic");
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print("🚫 Unsubscribed from topic: $topic");
  }

  Future<void> subscribeToOrderUpdates(String userId) async {
    await _firebaseMessaging.subscribeToTopic('order_$userId');
    print('✅ Subscribed to order updates for $userId');
  }

  Future<void> unsubscribeFromOrderUpdates(String userId) async {
    await _firebaseMessaging.unsubscribeFromTopic('order_$userId');
    print('🚫 Unsubscribed from order updates for $userId');
  }

  Future<void> subscribeAdminToOrders() async {
    await _firebaseMessaging.subscribeToTopic('admin_orders');
    print('✅ Subscribed to admin_orders');
  }

  Future<void> unsubscribeAdminFromOrders() async {
    await _firebaseMessaging.unsubscribeFromTopic('admin_orders');
    print('🚫 Unsubscribed from admin_orders');
  }

  // -------------------- 🔹 LOCAL NOTIFICATIONS --------------------
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'local_channel',
          'Local Notifications',
          channelDescription:
              'This channel is used for local reminders (not from FCM).',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  Future<void> initialize() async {
    await initializeNotifications();
  }
}
