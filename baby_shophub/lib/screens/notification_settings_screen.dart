import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Push Notifications
  bool _pushNotifications = true;
  bool _orderUpdates = true;
  bool _newArrivals = true;
  bool _promotions = true;
  bool _cartReminders = true;
  bool _deliveryUpdates = true;
  bool _securityAlerts = true;

  // Email Notifications
  bool _emailOrderUpdates = true;
  bool _emailPromotions = false;
  bool _emailNewsletters = false;
  bool _emailWeeklyDigest = true;

  // SMS Notifications
  bool _smsOrderUpdates = true;
  bool _smsDeliveryUpdates = true;
  bool _smsSecurityAlerts = true;

  // Marketing Communications
  bool _marketingEmails = false;
  bool _marketingSms = false;
  bool _marketingPush = false;
  bool _personalizedOffers = true;

  // Sound & Vibration
  bool _notificationSound = true;
  bool _notificationVibration = true;
  String _notificationSoundType = 'Default';

  final NotificationService _notificationService = NotificationService();
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user != null) {
        _userId = user.id;
        final settings = await _settingsService.getUserSettings(user.id);

        setState(() {
          _pushNotifications = settings['pushNotifications'] ?? true;
          _orderUpdates = settings['orderUpdates'] ?? true;
          _newArrivals = settings['newArrivals'] ?? true;
          _promotions = settings['promotions'] ?? true;
          _cartReminders = settings['cartReminders'] ?? true;
          _deliveryUpdates = settings['deliveryUpdates'] ?? true;
          _securityAlerts = settings['securityAlerts'] ?? true;

          _emailOrderUpdates = settings['emailOrderUpdates'] ?? true;
          _emailPromotions = settings['emailPromotions'] ?? false;
          _emailNewsletters = settings['emailNewsletters'] ?? false;
          _emailWeeklyDigest = settings['emailWeeklyDigest'] ?? true;

          _smsOrderUpdates = settings['smsOrderUpdates'] ?? true;
          _smsDeliveryUpdates = settings['smsDeliveryUpdates'] ?? true;
          _smsSecurityAlerts = settings['smsSecurityAlerts'] ?? true;

          _marketingEmails = settings['marketingEmails'] ?? false;
          _marketingSms = settings['marketingSms'] ?? false;
          _marketingPush = settings['marketingPush'] ?? false;
          _personalizedOffers = settings['personalizedOffers'] ?? true;

          _notificationSound = settings['notificationSound'] ?? true;
          _notificationVibration = settings['notificationVibration'] ?? true;
          _notificationSoundType =
              settings['notificationSoundType'] ?? 'Default';

          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load settings: $e')));
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    if (_userId == null) return;

    try {
      await _settingsService.updateSetting(_userId!, key, value);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save setting: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNeuroSection(
                    title: 'Push Notifications',
                    icon: Icons.notifications_active_rounded,
                    children: [
                      _buildNeuroSwitch(
                        title: 'Allow Notifications',
                        subtitle: 'Receive push notifications on this device',
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() => _pushNotifications = value);
                          _saveSetting('pushNotifications', value);
                        },
                      ),
                      if (_pushNotifications) ...[
                        const Divider(height: 1),
                        _buildNeuroSwitch(
                          title: 'Order Updates',
                          subtitle: 'Status updates for your orders',
                          value: _orderUpdates,
                          onChanged: (value) {
                            setState(() => _orderUpdates = value);
                            _saveSetting('orderUpdates', value);
                            _updateNotificationSubscription('order_updates', value);
                          },
                        ),
                        const Divider(height: 1),
                        _buildNeuroSwitch(
                          title: 'Promotions & Offers',
                          subtitle: 'Special deals and discount alerts',
                          value: _promotions,
                          onChanged: (value) {
                            setState(() => _promotions = value);
                            _saveSetting('promotions', value);
                            _updateNotificationSubscription('promotions', value);
                          },
                        ),
                        const Divider(height: 1),
                        _buildNeuroSwitch(
                          title: 'Delivery Updates',
                          subtitle: 'Real-time delivery status updates',
                          value: _deliveryUpdates,
                          onChanged: (value) {
                            setState(() => _deliveryUpdates = value);
                            _saveSetting('deliveryUpdates', value);
                            _updateNotificationSubscription('delivery_updates', value);
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildNeuroSection(
                    title: 'Email Preferences',
                    icon: Icons.email_rounded,
                    children: [
                      _buildNeuroSwitch(
                        title: 'Order Updates',
                        subtitle: 'Receive order receipts and updates',
                        value: _emailOrderUpdates,
                        onChanged: (value) {
                          setState(() => _emailOrderUpdates = value);
                          _saveSetting('emailOrderUpdates', value);
                        },
                      ),
                      const Divider(height: 1),
                      _buildNeuroSwitch(
                        title: 'Newsletters',
                        subtitle: 'Weekly trends and new arrivals',
                        value: _emailNewsletters,
                        onChanged: (value) {
                          setState(() => _emailNewsletters = value);
                          _saveSetting('emailNewsletters', value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildNeuroSection(
                    title: 'Sound & Vibration',
                    icon: Icons.volume_up_rounded,
                    children: [
                      _buildNeuroSwitch(
                        title: 'Play Sound',
                        subtitle: 'Play a sound for incoming notifications',
                        value: _notificationSound,
                        onChanged: (value) {
                          setState(() => _notificationSound = value);
                          _saveSetting('notificationSound', value);
                        },
                      ),
                      const Divider(height: 1),
                      _buildNeuroSwitch(
                        title: 'Vibrate',
                        subtitle: 'Vibrate for incoming notifications',
                        value: _notificationVibration,
                        onChanged: (value) {
                          setState(() => _notificationVibration = value);
                          _saveSetting('notificationVibration', value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNeuroSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF6366F1)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildNeuroSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Color(0xFF111827),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: const Color(0xFF6B7280).withOpacity(0.8),
          fontSize: 13,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF6366F1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  void _updateNotificationSubscription(String topic, bool subscribe) {
    if (subscribe) {
      _notificationService.subscribeToTopic(topic);
    } else {
      _notificationService.unsubscribeFromTopic(topic);
    }
  }
}
