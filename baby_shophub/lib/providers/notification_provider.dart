import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _notificationSubscription;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ Count unread notifications for a given user
  int unreadCount(String userId) {
    return _notifications.where((n) => !n.isReadBy(userId)).length;
  }

  // ✅ Initialize notification listener
  void initializeNotifications(String userId) {
    _isLoading = true;
    notifyListeners();

    _notificationSubscription = FirebaseFirestore.instance
        .collection(AppConstants.notificationsCollection)
        .where('userIds', arrayContainsAny: [userId, 'all'])
        .orderBy('sentAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) async {
            final newNotifications =
                snapshot.docs
                    .map((doc) => NotificationModel.fromMap(doc.data()))
                    .toList()
                  ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

            // 🔔 Detect only when a new notification arrives
            if (_notifications.isNotEmpty && newNotifications.isNotEmpty) {
              final latestOldId = _notifications.first.id;
              final latestNewId = newNotifications.first.id;

              if (latestNewId != latestOldId) {
                final newest = newNotifications.first;
                await _notificationService.showLocalNotification(
                  title: newest.title,
                  body: newest.message,
                  payload: newest.data?['type'] ?? 'general',
                );
              }
            }

            _notifications = newNotifications;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // ✅ Load notifications once (manual refresh)
  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _notificationService.getUserNotifications(userId);
      // Ensure newest first
      _notifications.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Mark notification as read
  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      await _notificationService.markAsRead(notificationId, userId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        if (!_notifications[index].readBy.contains(userId)) {
          _notifications[index].readBy.add(userId);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // ✅ Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      for (final notification in _notifications) {
        if (!notification.isReadBy(userId)) {
          await _notificationService.markAsRead(notification.id, userId);
          if (!notification.readBy.contains(userId)) {
            notification.readBy.add(userId);
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // ✅ Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // ✅ Clear all notifications (mark as read for now)
  Future<void> clearAll(String userId) async {
    try {
      await markAllAsRead(userId);
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
