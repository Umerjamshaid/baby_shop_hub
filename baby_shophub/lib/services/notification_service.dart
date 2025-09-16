import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:awesome_notifications/awesome_notifications.dart' as awesome;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notification_model.dart';
import '../utils/constants.dart';
import 'navigation_service.dart';

// Top-level background handler required by Firebase Messaging
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background isolate to avoid plugin exceptions
  try {
    await Firebase.initializeApp();
  } catch (_) {}
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

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
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
      print('🔔 onMessage: ${message.messageId}, data=${message.data}');
      _showNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
        '➡️ onMessageOpenedApp: ${message.messageId}, data=${message.data}',
      );
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

  Future<void> reconcileCurrentToken(String userId) async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      if (token == null) return;
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);
      final snap = await userRef.get();
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final List<dynamic> existing = (data['fcmTokens'] ?? []) as List<dynamic>;
      if (!existing.contains(token)) {
        await userRef.update({
          'fcmTokens': FieldValue.arrayUnion([token]),
        });
        print('🔧 Reconciled token for user: $userId');
      }
    } catch (e) {
      print('❌ Failed to reconcile token: $e');
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
      final String id = DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(id)
          .set({
            'id': id,
            'title': title,
            'message': message,
            'userIds': userIds,
            'imageUrl': imageUrl,
            'data': data,
            'sentAt': FieldValue.serverTimestamp(),
            'readBy': <String>[],
          });

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
          .where('userIds', arrayContainsAny: [userId, 'all'])
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
    final String title = message.notification?.title ?? 'BabyShopHub';
    final String body = message.notification?.body ?? 'New notification';
    final String? imageUrl =
        message.data['imageUrl'] ??
        message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl;

    try {
      final int nid =
          ((message.messageId?.hashCode ??
              DateTime.now().millisecondsSinceEpoch) &
          0x7fffffff);
      await awesome.AwesomeNotifications().createNotification(
        content: awesome.NotificationContent(
          id: nid,
          channelKey: 'order_updates',
          title: title,
          body: body,
          notificationLayout: imageUrl != null && imageUrl.isNotEmpty
              ? awesome.NotificationLayout.BigPicture
              : awesome.NotificationLayout.Default,
          bigPicture: imageUrl,
          payload: {
            'type': message.data['type']?.toString() ?? 'general',
            'productId': message.data['productId']?.toString() ?? '',
          },
        ),
      );
    } catch (_) {
      // Fallback to flutter_local_notifications
      const android = AndroidNotificationDetails(
        'order_updates',
        'Order Updates',
        channelDescription: 'Notifications for order status updates',
        importance: Importance.max,
        priority: Priority.high,
      );
      const iOS = DarwinNotificationDetails();
      await _flutterLocalNotificationsPlugin.show(
        ((message.messageId?.hashCode ??
                DateTime.now().millisecondsSinceEpoch) &
            0x7fffffff),
        title,
        body,
        const NotificationDetails(android: android, iOS: iOS),
        payload: message.data['type'] ?? 'general',
      );
    }
  }

  Future<String> _downloadToTemp(String url) async {
    final HttpClient client = HttpClient();
    final HttpClientRequest request = await client.getUrl(Uri.parse(url));
    final HttpClientResponse response = await request.close();
    final Uint8List bytes = await consolidateHttpClientResponseBytes(response);
    final Directory dir = await getTemporaryDirectory();
    final String filePath =
        '${dir.path}/n_${DateTime.now().millisecondsSinceEpoch}.img';
    final File file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
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
      case 'product':
        final pid = data['productId']?.toString();
        if (pid != null && pid.isNotEmpty) {
          navigator.pushNamed('/product', arguments: {'id': pid});
          return;
        }
        navigator.pushNamed('/home');
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
    try {
      await awesome.AwesomeNotifications().createNotification(
        content: awesome.NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch,
          channelKey: 'local_channel',
          title: title,
          body: body,
          payload: payload == null ? null : {'type': payload},
        ),
      );
    } catch (_) {
      const android = AndroidNotificationDetails(
        'local_channel',
        'Local Notifications',
        channelDescription:
            'This channel is used for local reminders (not from FCM).',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iOS = DarwinNotificationDetails();
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch,
        title,
        body,
        const NotificationDetails(android: android, iOS: iOS),
        payload: payload,
      );
    }
  }

  Future<void> initialize() async {
    await initializeNotifications();
  }
}
