import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/app_button.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ Fix: delay notification load until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  void _loadNotifications() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      notificationProvider.loadNotifications(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (authProvider.currentUser != null &&
              notificationProvider.unreadCount(authProvider.currentUser!.id) > 0)
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              onPressed: () {
                notificationProvider.markAllAsRead(authProvider.currentUser!.id);
              },
              tooltip: 'Mark all as read',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(notificationProvider, authProvider),
    );

  }

  Widget _buildBody(NotificationProvider notificationProvider, AuthProvider authProvider) {
    if (notificationProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notificationProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Error: ${notificationProvider.error}'),
            const SizedBox(height: 16),
            AppButton(
              onPressed: _loadNotifications,
              text: 'Try Again',
            ),
          ],
        ),
      );
    }

    if (notificationProvider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No notifications yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'You\'ll see notifications here when you receive them',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadNotifications();
      },
      child: ListView.builder(
        itemCount: notificationProvider.notifications.length,
        itemBuilder: (context, index) {
          final notification = notificationProvider.notifications[index];
          final isRead = authProvider.currentUser != null
              ? notification.isReadBy(authProvider.currentUser!.id)
              : false;

          return Dismissible(
            key: Key(notification.id),
            background: Container(color: Colors.red),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              if (authProvider.currentUser != null) {
                notificationProvider.markAsRead(notification.id, authProvider.currentUser!.id);
              }
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: isRead ? Colors.white : Colors.blue[50],
              child: ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: isRead ? Colors.grey : Colors.blue,
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.message),
                    const SizedBox(height: 4),
                    Text(
                      notification.formattedDate,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: !isRead
                    ? const Icon(Icons.circle, size: 12, color: Colors.blue)
                    : null,
                onTap: () {
                  if (authProvider.currentUser != null && !isRead) {
                    notificationProvider.markAsRead(notification.id, authProvider.currentUser!.id);
                  }

                  // Handle notification tap (navigate to relevant screen)
                  _handleNotificationTap(notification);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Handle different types of notifications
    if (notification.data != null) {
      final type = notification.data!['type'];
      final id = notification.data!['id'];

      switch (type) {
        case 'order':
        // Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailScreen(orderId: id)));
          break;
        case 'product':
        // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: id)));
          break;
        case 'promotion':
        // Navigator.push(context, MaterialPageRoute(builder: (context) => PromotionsScreen()));
          break;
      }
    }
  }
}
