import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/pretty_notification_card.dart';

class NotificationCentreScreen extends StatefulWidget {
  const NotificationCentreScreen({super.key});

  @override
  State<NotificationCentreScreen> createState() =>
      _NotificationCentreScreenState();
}

class _NotificationCentreScreenState extends State<NotificationCentreScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final userId = authProvider.currentUser?.id ?? '';

    // Group notifications by date
    final groupedNotifications = _groupNotificationsByDate(
      notificationProvider.notifications,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notification Centre'),
        actions: [
          if (notificationProvider.notifications.isNotEmpty)
            TextButton(
              onPressed: () => notificationProvider.markAllAsRead(userId),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notificationProvider.notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: groupedNotifications.length,
              itemBuilder: (context, index) {
                final group = groupedNotifications[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        group['date'] as String,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Notifications for this date
                    ...(group['notifications'] as List<NotificationModel>).map((
                      notif,
                    ) {
                      return PrettyNotificationCard(
                        notif: notif,
                        userId: userId,
                        onTap: () => _handleNotificationTap(notif),
                        onDismiss: () =>
                            notificationProvider.deleteNotification(notif.id),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }

  List<Map<String, dynamic>> _groupNotificationsByDate(
    List<NotificationModel> notifications,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<NotificationModel>>{};

    for (final notif in notifications) {
      final notifDate = DateTime(
        notif.sentAt.year,
        notif.sentAt.month,
        notif.sentAt.day,
      );
      String dateKey;

      if (notifDate == today) {
        dateKey = 'Today';
      } else if (notifDate == yesterday) {
        dateKey = 'Yesterday';
      } else if (notif.sentAt.isAfter(
        today.subtract(const Duration(days: 7)),
      )) {
        dateKey = 'Earlier this week';
      } else {
        dateKey = 'Older';
      }

      groups.putIfAbsent(dateKey, () => []).add(notif);
    }

    // Sort groups in order: Today, Yesterday, Earlier this week, Older
    final order = ['Today', 'Yesterday', 'Earlier this week', 'Older'];
    return order.where((key) => groups.containsKey(key)).map((key) {
      return {'date': key, 'notifications': groups[key]!};
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see your notifications here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUser != null &&
        !notification.isReadBy(authProvider.currentUser!.id)) {
      notificationProvider.markAsRead(
        notification.id,
        authProvider.currentUser!.id,
      );
    }

    // Handle deep linking based on notification type
    if (notification.data != null) {
      final type = notification.data!['type'];
      final id =
          notification.data!['productId'] ?? notification.data!['orderId'];

      switch (type) {
        case 'price_drop':
        case 'product':
          if (id != null) {
            Navigator.pushNamed(context, '/product', arguments: {'id': id});
          }
          break;
        case 'cart_reminder':
          Navigator.pushNamed(context, '/cart');
          break;
        case 'order_shipped':
          if (id != null) {
            Navigator.pushNamed(
              context,
              '/order-tracking',
              arguments: {'orderId': id},
            );
          }
          break;
        default:
          // Handle other types or fallback
          break;
      }
    }
  }
}
