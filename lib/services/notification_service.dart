import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
// Removed unused imports
import 'package:awesome_notifications/awesome_notifications.dart' as awesome;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/notification_model.dart';
import '../utils/constants.dart';
import 'navigation_service.dart';
import 'favorites_service.dart';

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
    // Request Firebase Messaging permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted FCM permission');
    }

    // Request Awesome Notifications permissions
    final isAllowed = await awesome.AwesomeNotifications()
        .isNotificationAllowed();
    if (!isAllowed) {
      await awesome.AwesomeNotifications()
          .requestPermissionToSendNotifications();
      print('✅ Requested Awesome Notifications permission');
    }

    String? token;
    try {
      token = await _firebaseMessaging.getToken();
      print("📲 FCM Token: $token");
    } catch (e) {
      print("⚠️ FCM Token Error: $e");
      // Continue initialization even if token fails
    }

    // Initialize Flutter Local Notifications
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

    // Initialize Awesome Notifications with all channels
    await awesome.AwesomeNotifications()
        .initialize('resource://drawable/ic_launcher', [
          awesome.NotificationChannel(
            channelKey: 'order_updates',
            channelName: 'Order Updates',
            channelDescription: 'Notifications for order status updates',
            importance: awesome.NotificationImportance.High,
            defaultColor: const Color(0xFF2196F3),
            ledColor: const Color(0xFF2196F3),
            channelShowBadge: true,
            enableLights: true,
            enableVibration: true,
            playSound: true,
            icon: 'resource://drawable/ic_launcher',
          ),
          awesome.NotificationChannel(
            channelKey: 'local_channel',
            channelName: 'Local Notifications',
            channelDescription: 'Local reminders and app events',
            importance: awesome.NotificationImportance.High,
            defaultColor: const Color(0xFF2196F3),
            ledColor: const Color(0xFF2196F3),
            channelShowBadge: true,
            enableLights: true,
            enableVibration: true,
            playSound: true,
            icon: 'resource://drawable/ic_launcher',
          ),
          awesome.NotificationChannel(
            channelKey: 'rich_channel',
            channelName: 'Rich Notifications',
            channelDescription: 'Big-picture & action-button notifications',
            defaultColor: const Color(0xFF2196F3),
            importance: awesome.NotificationImportance.High,
            channelShowBadge: true,
            enableLights: true,
            enableVibration: true,
            playSound: true,
            icon: 'resource://drawable/ic_launcher',
          ),
        ]);

    // Listen to Awesome Notifications action buttons
    try {
      await awesome.AwesomeNotifications().setListeners(
        onActionReceivedMethod: (received) async {
          final String action = received.buttonKeyPressed;
          final Map<String, String?> payload = received.payload ?? {};
          final String type = payload['type'] ?? 'general';
          if (type == 'product') {
            final String? productId = payload['productId'];
            if (action == 'VIEW' && productId != null && productId.isNotEmpty) {
              _openRoute('/product/$productId');
            }
            if (action == 'SAVE' && productId != null && productId.isNotEmpty) {
              try {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await FavoritesService().addToFavorites(uid, productId);
                  await showLocalNotification(
                    title: 'Saved',
                    body: 'Product added to favorites',
                    payload: 'general',
                  );
                }
              } catch (_) {}
            }
          }
        },
      );
    } catch (_) {}
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
      String? token = await _firebaseMessaging.getToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
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
      final String? token = await _firebaseMessaging.getToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
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
          .get();

      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
      
      // Sort client-side to avoid index requirement
      notifications.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      
      return notifications;
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

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // -------------------- 🔹 FCM HANDLERS --------------------
  // Background handled by top-level function

  Future<void> _showNotification(RemoteMessage msg) async {
    final data = msg.data;
    final type = data['type'] ?? 'general';
    final title = msg.notification?.title ?? 'BabyShopHub';
    final body = msg.notification?.body ?? '';
    final img =
        data['imageUrl'] ??
        msg.notification?.android?.imageUrl ??
        msg.notification?.apple?.imageUrl;

    // 1. Build dynamic big-picture card
    String? bigPicture;
    if (img != null && img.isNotEmpty) {
      bigPicture = await _getLocalImagePath(img); // cached
    }

    // 2. Action buttons (Daraz style)
    List<awesome.NotificationActionButton> actions = [];
    if (type == 'price_drop' || type == 'product') {
      actions = [
        awesome.NotificationActionButton(
          key: 'VIEW',
          label: 'View Product',
          actionType: awesome.ActionType.Default,
        ),
        awesome.NotificationActionButton(
          key: 'SAVE',
          label: 'Save for Later',
          actionType: awesome.ActionType.Default,
        ),
      ];
    } else if (type == 'order_shipped') {
      actions = [
        awesome.NotificationActionButton(
          key: 'TRACK',
          label: 'Track Order',
          actionType: awesome.ActionType.Default,
        ),
      ];
    }

    // 3. Send rich card
    final int id = _generateSafeNotificationId();
    await awesome.AwesomeNotifications().createNotification(
      content: awesome.NotificationContent(
        id: id,
        channelKey: 'rich_channel',
        title: title,
        body: _buildRichBody(type, data, body), // see helper below
        notificationLayout: bigPicture != null
            ? awesome.NotificationLayout.BigPicture
            : awesome.NotificationLayout.Default,
        bigPicture: bigPicture,
        largeIcon: bigPicture,
        payload: data.map((k, v) => MapEntry(k, v.toString())),
      ),
      actionButtons: actions,
    );
  }

  String _buildRichBody(
    String type,
    Map<String, dynamic> data,
    String fallback,
  ) {
    switch (type) {
      case 'price_drop':
        return '🔥 ${data['discount']}% OFF – was \$${data['oldPrice']} now \$${data['newPrice']}';
      case 'stock_low':
        return '⚠️ Only ${data['stockLeft']} left in stock – hurry!';
      case 'cart_reminder':
        return '🛒 You left ${data['items']} items (${data['total']}) in your cart';
      case 'order_shipped':
        return '🚚 Order #${data['orderId']} is out for delivery';
      default:
        return fallback;
    }
  }

  // Removed unused temporary download helper

  void _handleMessage(RemoteMessage message) {
    final String type = message.data['type'] ?? 'general';
    _handleNotificationType(type, message.data);
  }

  void _handleNotificationTap(NotificationResponse response) {
    final data = _decodePayload(response.payload);
    final String type = data['type']?.toString() ?? response.payload ?? 'general';
    _handleNotificationType(type, data);
  }

  Map<String, dynamic> _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return {};
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}
    return {'type': payload};
  }

  Map<String, String?>? _payloadMap(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final decoded = _decodePayload(payload);
    return decoded.map((key, value) => MapEntry(key, value?.toString()));
  }

  void _openRoute(String location) {
    final router = NavigationService.router;
    if (router != null) {
      router.go(location);
      return;
    }
    NavigationService.navigatorKey.currentContext?.go(location);
  }

  void _handleNotificationType(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'price_drop':
      case 'product':
        final pid = data['productId'] as String?;
        if (pid != null && pid.isNotEmpty) {
          _openRoute('/product/$pid');
        }
        break;
      case 'cart_reminder':
        _openRoute('/cart');
        break;
      case 'order_shipped':
        final orderId = data['orderId'] as String?;
        if (orderId != null && orderId.isNotEmpty) {
          _openRoute('/order-tracking/$orderId');
        } else {
          _openRoute('/orders');
        }
        break;
      case 'order_update':
        final orderId = data['orderId']?.toString();
        if (orderId != null && orderId.isNotEmpty) {
          _openRoute('/order-detail/$orderId');
        } else {
          _openRoute('/orders');
        }
        return;
      case 'order_delivered':
        final orderId = data['orderId']?.toString();
        if (orderId != null && orderId.isNotEmpty) {
          _openRoute('/order-detail/$orderId');
        } else {
          _openRoute('/orders');
        }
        return;
      case 'new_arrival':
      case 'offer':
      case 'general':
      default:
        _openRoute('/home');
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
    String? imageUrl,
  }) async {
    // Generate a safe notification ID within 32-bit integer range
    final int safeId = _generateSafeNotificationId();

    // Download and cache image if provided
    String? localImagePath;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      localImagePath = await _getLocalImagePath(imageUrl);
    }

    try {
      await awesome.AwesomeNotifications().createNotification(
        content: awesome.NotificationContent(
          id: safeId,
          channelKey: 'local_channel',
          title: title,
          body: body,
          notificationLayout: localImagePath != null
              ? awesome.NotificationLayout.BigPicture
              : awesome.NotificationLayout.Default,
          bigPicture: localImagePath,
          largeIcon: localImagePath,
          payload: payload == null ? null : {'type': payload},
        ),
      );
    } catch (e) {
      print('❌ Awesome Notifications failed for local: $e');
      // Fallback to flutter_local_notifications
      try {
        late AndroidNotificationDetails android;
        if (localImagePath != null) {
          android = AndroidNotificationDetails(
            'local_channel',
            'Local Notifications',
            channelDescription:
                'This channel is used for local reminders (not from FCM).',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigPictureStyleInformation(
              FilePathAndroidBitmap(localImagePath),
              contentTitle: title,
              summaryText: body,
            ),
          );
        } else {
          android = const AndroidNotificationDetails(
            'local_channel',
            'Local Notifications',
            channelDescription:
                'This channel is used for local reminders (not from FCM).',
            importance: Importance.high,
            priority: Priority.high,
          );
        }

        const iOS = DarwinNotificationDetails();
        await _flutterLocalNotificationsPlugin.show(
          safeId,
          title,
          body,
          NotificationDetails(android: android, iOS: iOS),
          payload: payload,
        );
      } catch (fallbackError) {
        print('❌ Fallback local notification failed: $fallbackError');
        // Final fallback - text only
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
          safeId,
          title,
          body,
          const NotificationDetails(android: android, iOS: iOS),
          payload: payload,
        );
      }
    }
  }

  // Generate a safe notification ID within 32-bit integer range
  int _generateSafeNotificationId() {
    // Use current time in seconds (much smaller) combined with a hash
    final int timestamp =
        DateTime.now().millisecondsSinceEpoch ~/ 1000; // Convert to seconds
    final int hash = timestamp.hashCode.abs(); // Get positive hash
    // Ensure it fits within 32-bit signed integer range
    return hash % 0x7FFFFFFF; // Max 32-bit signed integer
  }

  // -------------------- 🔹 IMAGE DOWNLOAD & CACHING --------------------
  Future<String?> _downloadAndCacheImage(String imageUrl) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(
        imageUrl.split('?').first,
      ); // Remove query params
      final localPath = path.join(
        tempDir.path,
        'notification_images',
        fileName,
      );

      // Create directory if it doesn't exist
      final imageDir = Directory(path.dirname(localPath));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      // Check if file already exists
      final localFile = File(localPath);
      if (await localFile.exists()) {
        return localPath;
      }

      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        await localFile.writeAsBytes(response.bodyBytes);
        return localPath;
      } else {
        print('❌ Failed to download image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error downloading image: $e');
      return null;
    }
  }

  Future<String?> _getLocalImagePath(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    // If it's already a local file path, return as is
    if (imageUrl.startsWith('/') || imageUrl.contains('file://')) {
      return imageUrl;
    }

    // If it's a network URL, download and cache it
    if (imageUrl.startsWith('http')) {
      return await _downloadAndCacheImage(imageUrl);
    }

    // For other cases, return null
    return null;
  }

  // -------------------- 🔹 ORDER-SPECIFIC NOTIFICATIONS --------------------

  /// Send order status update notification
  Future<void> sendOrderStatusNotification({
    required String userId,
    required String orderId,
    required String status,
    String? trackingNumber,
    String? carrier,
  }) async {
    String title;
    String body;
    String type;

    switch (status) {
      case 'Processing':
        title = 'Order Processing Started';
        body = 'Your order #$orderId is now being processed';
        type = 'order_update';
        break;
      case 'Confirmed':
        title = 'Order Confirmed';
        body = 'Your order #$orderId has been confirmed';
        type = 'order_update';
        break;
      case 'Shipped':
        title = 'Order Shipped!';
        body = trackingNumber != null
            ? 'Your order #$orderId has been shipped. Track with: $trackingNumber'
            : 'Your order #$orderId has been shipped';
        type = 'order_shipped';
        break;
      case 'Delivered':
        title = 'Order Delivered!';
        body = 'Your order #$orderId has been delivered successfully';
        type = 'order_delivered';
        break;
      case 'Cancelled':
        title = 'Order Cancelled';
        body = 'Your order #$orderId has been cancelled';
        type = 'order_update';
        break;
      default:
        title = 'Order Update';
        body = 'Your order #$orderId status: $status';
        type = 'order_update';
    }

    // Send to specific user topic
    await sendNotificationToUsers(
      title: title,
      message: body,
      userIds: [userId],
      data: {
        'type': type,
        'orderId': orderId,
        'status': status,
        'trackingNumber': trackingNumber,
        'carrier': carrier,
      },
    );

    // Also send local notification if app is in foreground
    await showLocalNotification(
      title: title,
      body: body,
      payload: jsonEncode({
        'type': type,
        'orderId': orderId,
        'status': status,
        if (trackingNumber != null) 'trackingNumber': trackingNumber,
        if (carrier != null) 'carrier': carrier,
      }),
    );
  }

  /// Send shipment tracking update notification
  Future<void> sendShipmentTrackingNotification({
    required String userId,
    required String orderId,
    required String trackingNumber,
    required String carrier,
    String? status,
  }) async {
    final title = 'Shipment Update';
    final body = 'Tracking update for order #$orderId: $status';

    await sendNotificationToUsers(
      title: title,
      message: body,
      userIds: [userId],
      data: {
        'type': 'order_shipped',
        'orderId': orderId,
        'trackingNumber': trackingNumber,
        'carrier': carrier,
        'status': status,
      },
    );
  }

  /// Send delivery confirmation notification
  Future<void> sendDeliveryNotification({
    required String userId,
    required String orderId,
  }) async {
    await sendNotificationToUsers(
      title: 'Package Delivered!',
      message: 'Your order #$orderId has been delivered. Enjoy your purchase!',
      userIds: [userId],
      data: {'type': 'order_delivered', 'orderId': orderId},
    );
  }

  /// Send product notification with image
  Future<void> sendProductNotification({
    required String userId,
    required String productId,
    required String productName,
    required String productImage,
    required double price,
    String type = 'product',
    String? discount,
  }) async {
    String title;
    String body;

    switch (type) {
      case 'price_drop':
        title = '🔥 Price Drop Alert!';
        body = '$productName is now \$$price${discount != null ? " ($discount% OFF)" : ""}';
        break;
      case 'back_in_stock':
        title = '✨ Back in Stock!';
        body = '$productName is available again. Get it before it\'s gone!';
        break;
      case 'new_arrival':
        title = '🎉 New Arrival!';
        body = 'Check out $productName - just added to our collection!';
        break;
      default:
        title = 'BabyShopHub';
        body = 'Check out $productName';
    }

    await sendNotificationToUsers(
      title: title,
      message: body,
      userIds: [userId],
      imageUrl: productImage,
      data: {
        'type': type,
        'productId': productId,
        'imageUrl': productImage,
        'price': price.toString(),
        if (discount != null) 'discount': discount,
      },
    );

    // Also send local notification with image
    await showLocalNotification(
      title: title,
      body: body,
      payload: type,
      imageUrl: productImage,
    );
  }

  Future<void> initialize() async {
    await initializeNotifications();
  }
}
