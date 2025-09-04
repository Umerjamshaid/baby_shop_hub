import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _orderUpdates = true;
  bool _newArrivals = true;
  bool _promotions = true;
  bool _cartReminders = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Order Updates'),
              value: _orderUpdates,
              onChanged: (value) {
                setState(() {
                  _orderUpdates = value;
                });
                _updateNotificationSubscription('order_updates', value);
              },
            ),
            SwitchListTile(
              title: const Text('New Arrivals'),
              value: _newArrivals,
              onChanged: (value) {
                setState(() {
                  _newArrivals = value;
                });
                _updateNotificationSubscription('new_arrivals', value);
              },
            ),
            SwitchListTile(
              title: const Text('Promotions & Offers'),
              value: _promotions,
              onChanged: (value) {
                setState(() {
                  _promotions = value;
                });
                _updateNotificationSubscription('promotions', value);
              },
            ),
            SwitchListTile(
              title: const Text('Cart Reminders'),
              value: _cartReminders,
              onChanged: (value) {
                setState(() {
                  _cartReminders = value;
                });
                _updateNotificationSubscription('cart_reminders', value);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateNotificationSubscription(String topic, bool subscribe) {
    if (subscribe) {
      NotificationService.subscribeToTopic(topic);
    } else {
      NotificationService.unsubscribeFromTopic(topic);
    }
  }
}