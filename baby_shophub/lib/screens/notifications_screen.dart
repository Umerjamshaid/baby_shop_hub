import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

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
              notificationProvider.unreadCount(authProvider.currentUser!.id) >
                  0)
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              onPressed: () {
                notificationProvider.markAllAsRead(
                  authProvider.currentUser!.id,
                );
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

  Widget _buildBody(
    NotificationProvider notificationProvider,
    AuthProvider authProvider,
  ) {
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
            AppButton(onPressed: _loadNotifications, text: 'Try Again'),
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

          return Card(
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
                  if (notification.imageUrl != null &&
                      notification.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          notification.imageUrl!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 140,
                                color: Colors.grey[200],
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey[500],
                                ),
                              ),
                        ),
                      ),
                    ),
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
                  notificationProvider.markAsRead(
                    notification.id,
                    authProvider.currentUser!.id,
                  );
                }
                _handleNotificationTap(notification);
              },
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
      final id = notification.data!['productId'] ?? notification.data!['id'];

      switch (type) {
        case 'order':
          // TODO: Implement order detail screen navigation if available
          break;
        case 'product':
          if (id != null && id is String && id.isNotEmpty) {
            Navigator.pushNamed(context, '/product', arguments: {'id': id});
          }
          break;
        case 'promotion':
          // TODO: Implement promotions screen if available
          break;
        default:
          // Fallback to home
          Navigator.pushNamed(context, '/home');
      }
    }
  }
}
