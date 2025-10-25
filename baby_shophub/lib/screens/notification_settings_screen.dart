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
          _pushNotifications = settings.pushNotifications;
          _orderUpdates = settings.orderUpdates;
          _newArrivals = settings.newArrivals;
          _promotions = settings.promotions;
          _cartReminders = settings.cartReminders;
          _deliveryUpdates = settings.deliveryUpdates;
          _securityAlerts = settings.securityAlerts;

          _emailOrderUpdates = settings.emailOrderUpdates;
          _emailPromotions = settings.emailPromotions;
          _emailNewsletters = settings.emailNewsletters;
          _emailWeeklyDigest = settings.emailWeeklyDigest;

          _smsOrderUpdates = settings.smsOrderUpdates;
          _smsDeliveryUpdates = settings.smsDeliveryUpdates;
          _smsSecurityAlerts = settings.smsSecurityAlerts;

          _marketingEmails = settings.marketingEmails;
          _marketingSms = settings.marketingSms;
          _marketingPush = settings.marketingPush;
          _personalizedOffers = settings.personalizedOffers;

          _notificationSound = settings.notificationSound;
          _notificationVibration = settings.notificationVibration;
          _notificationSoundType = settings.notificationSoundType;

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
      appBar: AppBar(
        title: const Text('Notification Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading settings...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Push Notifications Section
                  _buildSection(
                    title: '🔔 Push Notifications',
                    children: [
                      _buildSwitchTile(
                        title: 'Push Notifications',
                        subtitle: 'Receive push notifications on this device',
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() => _pushNotifications = value);
                          _saveSetting('pushNotifications', value);
                        },
                      ),
                      if (_pushNotifications) ...[
                        _buildSwitchTile(
                          title: 'Order Updates',
                          subtitle: 'Status updates for your orders',
                          value: _orderUpdates,
                          onChanged: (value) {
                            setState(() => _orderUpdates = value);
                            _saveSetting('orderUpdates', value);
                            _updateNotificationSubscription(
                              'order_updates',
                              value,
                            );
                          },
                        ),
                        _buildSwitchTile(
                          title: 'New Arrivals',
                          subtitle: 'Notifications about new products',
                          value: _newArrivals,
                          onChanged: (value) {
                            setState(() => _newArrivals = value);
                            _saveSetting('newArrivals', value);
                            _updateNotificationSubscription(
                              'new_arrivals',
                              value,
                            );
                          },
                        ),
                        _buildSwitchTile(
                          title: 'Promotions & Offers',
                          subtitle: 'Special deals and discount alerts',
                          value: _promotions,
                          onChanged: (value) {
                            setState(() => _promotions = value);
                            _saveSetting('promotions', value);
                            _updateNotificationSubscription(
                              'promotions',
                              value,
                            );
                          },
                        ),
                        _buildSwitchTile(
                          title: 'Cart Reminders',
                          subtitle: 'Reminders about items in your cart',
                          value: _cartReminders,
                          onChanged: (value) {
                            setState(() => _cartReminders = value);
                            _saveSetting('cartReminders', value);
                            _updateNotificationSubscription(
                              'cart_reminders',
                              value,
                            );
                          },
                        ),
                        _buildSwitchTile(
                          title: 'Delivery Updates',
                          subtitle: 'Real-time delivery status updates',
                          value: _deliveryUpdates,
                          onChanged: (value) {
                            setState(() => _deliveryUpdates = value);
                            _saveSetting('deliveryUpdates', value);
                            _updateNotificationSubscription(
                              'delivery_updates',
                              value,
                            );
                          },
                        ),
                        _buildSwitchTile(
                          title: 'Security Alerts',
                          subtitle: 'Important security notifications',
                          value: _securityAlerts,
                          onChanged: (value) {
                            setState(() => _securityAlerts = value);
                            _saveSetting('securityAlerts', value);
                            _updateNotificationSubscription(
                              'security_alerts',
                              value,
                            );
                          },
                        ),
                      ],
                    ],
                  ),

                  // Email Notifications Section
                  _buildSection(
                    title: '📧 Email Notifications',
                    children: [
                      _buildSwitchTile(
                        title: 'Order Updates',
                        subtitle: 'Email updates about your orders',
                        value: _emailOrderUpdates,
                        onChanged: (value) {
                          setState(() => _emailOrderUpdates = value);
                          _saveSetting('emailOrderUpdates', value);
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Promotions & Offers',
                        subtitle: 'Special deals and offers via email',
                        value: _emailPromotions,
                        onChanged: (value) {
                          setState(() => _emailPromotions = value);
                          _saveSetting('emailPromotions', value);
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Newsletters',
                        subtitle: 'Weekly newsletters and updates',
                        value: _emailNewsletters,
                        onChanged: (value) {
                          setState(() => _emailNewsletters = value);
                          _saveSetting('emailNewsletters', value);
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Weekly Digest',
                        subtitle: 'Weekly summary of your activity',
                        value: _emailWeeklyDigest,
                        onChanged: (value) {
                          setState(() => _emailWeeklyDigest = value);
                          _saveSetting('emailWeeklyDigest', value);
                        },
                      ),
                    ],
                  ),

                  // SMS Notifications Section
                  _buildSection(
                    title: '💬 SMS Notifications',
                    children: [
                      _buildSwitchTile(
                        title: 'Order Updates',
                        subtitle: 'SMS updates about your orders',
                        value: _smsOrderUpdates,
                        onChanged: (value) {
                          setState(() => _smsOrderUpdates = value);
                          _saveSetting('smsOrderUpdates', value);
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Delivery Updates',
                        subtitle: 'SMS delivery status updates',
                        value: _smsDeliveryUpdates,
                        onChanged: (value) {
                          setState(() => _smsDeliveryUpdates = value);
                          _saveSetting('smsDeliveryUpdates', value);
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Security Alerts',
                        subtitle: 'Important security notifications via SMS',
                        value: _smsSecurityAlerts,
                        onChanged: (value) {
                          setState(() => _smsSecurityAlerts = value);
                          _saveSetting('smsSecurityAlerts', value);
                        },
                      ),
                    ],
                  ),

                  // Marketing Communications Section
                  _buildSection(
                    title: '📢 Marketing Communications',
                    children: [
                      _buildSwitchTile(
                        title: 'Marketing Emails',
                        subtitle: 'Receive marketing emails and offers',
                        value: _marketingEmails,
                        onChanged: (value) {
                          setState(() => _marketingEmails = value);
                          _saveSetting('marketingEmails', value);
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Marketing SMS',
                        subtitle: 'Receive marketing messages via SMS',
                        value: _marketingSms,
                        onChanged: (value) {
                          setState(() => _marketingSms = value);
                          _saveSetting('marketingSms', value);
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Marketing Push Notifications',
                        subtitle: 'Receive marketing push notifications',
                        value: _marketingPush,
                        onChanged: (value) {
                          setState(() => _marketingPush = value);
                          _saveSetting('marketingPush', value);
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Personalized Offers',
                        subtitle: 'Receive offers based on your preferences',
                        value: _personalizedOffers,
                        onChanged: (value) {
                          setState(() => _personalizedOffers = value);
                          _saveSetting('personalizedOffers', value);
                        },
                      ),
                    ],
                  ),

                  // Sound & Vibration Section
                  _buildSection(
                    title: '🔊 Sound & Vibration',
                    children: [
                      _buildSwitchTile(
                        title: 'Notification Sound',
                        subtitle: 'Play sound for notifications',
                        value: _notificationSound,
                        onChanged: (value) {
                          setState(() => _notificationSound = value);
                          _saveSetting('notificationSound', value);
                        },
                      ),
                      if (_notificationSound)
                        _buildDropdownTile(
                          title: 'Sound Type',
                          value: _notificationSoundType,
                          options: ['Default', 'Chime', 'Bell', 'Gentle'],
                          onChanged: (value) {
                            setState(() => _notificationSoundType = value!);
                            _saveSetting('notificationSoundType', value);
                          },
                        ),
                      _buildSwitchTile(
                        title: 'Vibration',
                        subtitle: 'Vibrate for notifications',
                        value: _notificationVibration,
                        onChanged: (value) {
                          setState(() => _notificationVibration = value);
                          _saveSetting('notificationVibration', value);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Notification Preferences',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can change these settings anytime. Some notifications may be required for account security and order updates.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF6C5CE7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: DropdownButton<String>(
        value: value,
        items: options.map((String option) {
          return DropdownMenuItem<String>(value: option, child: Text(option));
        }).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
