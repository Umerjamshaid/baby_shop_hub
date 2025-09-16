import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../services/user_service.dart';
import '../../services/notification_service.dart';
import '../../models/user_model.dart';
import '../../widgets/common/app_button.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  State<NotificationManagementScreen> createState() =>
      _NotificationManagementScreenState();
}

class _NotificationManagementScreenState
    extends State<NotificationManagementScreen> {
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  Set<String> _selectedUserIds = {};
  bool _selectAll = false;
  bool _sendToAll = false;
  bool _isLoading = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _filteredUsers = _allUsers;
      });
    } else {
      setState(() {
        _filteredUsers = _allUsers.where((user) {
          return user.name.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedUserIds = Set.from(_filteredUsers.map((user) => user.id));
      } else {
        _selectedUserIds.clear();
      }
    });
  }

  void _toggleUserSelection(String userId, bool selected) {
    setState(() {
      if (selected) {
        _selectedUserIds.add(userId);
      } else {
        _selectedUserIds.remove(userId);
      }

      // Update select all checkbox state
      _selectAll = _selectedUserIds.length == _filteredUsers.length;
    });
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title and message')),
      );
      return;
    }

    if (!_sendToAll && _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user')),
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      // Parse optional JSON payload
      Map<String, dynamic>? extraData;
      if (_dataController.text.trim().isNotEmpty) {
        try {
          final parsed = jsonDecode(_dataController.text.trim());
          if (parsed is Map<String, dynamic>) {
            extraData = parsed;
          }
        } catch (_) {
          // Invalid JSON, ignore
        }
      }

      final List<String> targetUserIds = _sendToAll
          ? ['all']
          : _selectedUserIds.toList();

      await _notificationService.sendNotificationToUsers(
        title: _titleController.text,
        message: _messageController.text,
        userIds: targetUserIds,
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        data: extraData,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent successfully!')),
      );

      // Clear form
      _titleController.clear();
      _messageController.clear();
      _imageUrlController.clear();
      _dataController.clear();
      setState(() {
        _selectedUserIds.clear();
        _selectAll = false;
        _sendToAll = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: $e')),
      );
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }

  Future<void> _sendToAllUsers() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title and message')),
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      // Parse optional JSON payload
      Map<String, dynamic>? extraData;
      if (_dataController.text.trim().isNotEmpty) {
        try {
          final parsed = jsonDecode(_dataController.text.trim());
          if (parsed is Map<String, dynamic>) {
            extraData = parsed;
          }
        } catch (_) {}
      }

      // Write Firestore doc with userIds: ['all'] so Cloud Function broadcasts
      await _notificationService.sendNotificationToUsers(
        title: _titleController.text,
        message: _messageController.text,
        userIds: const ['all'],
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        data: extraData,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent to all users!')),
      );

      // Clear form
      _titleController.clear();
      _messageController.clear();
      _imageUrlController.clear();
      _dataController.clear();
      setState(() {
        _selectedUserIds.clear();
        _selectAll = false;
        _sendToAll = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: $e')),
      );
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Send Notifications'),
        backgroundColor: Colors.white,
        elevation: 1,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Notification Form
            _buildNotificationForm(),

            // User Selection
            _buildUserList(),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationForm() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compose Notification',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _DebugTools(),
            const SizedBox(height: 12),
            _buildCompactTextField(
              controller: _titleController,
              label: 'Title',
              icon: Icons.title,
            ),
            const SizedBox(height: 10),
            _buildCompactTextField(
              controller: _messageController,
              label: 'Message',
              icon: Icons.message,
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            _buildCompactTextField(
              controller: _imageUrlController,
              label: 'Image URL (optional)',
              icon: Icons.image,
            ),
            const SizedBox(height: 10),
            _buildCompactTextField(
              controller: _dataController,
              label: 'Payload (JSON)',
              icon: Icons.data_object,
              hintText: '{"type":"offer","id":"123"}',
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                title: const Text(
                  'Send to all users',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                value: _sendToAll,
                onChanged: (v) {
                  setState(() {
                    _sendToAll = v;
                  });
                },
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
  }) {
    return Container(
      height: maxLines == 1 ? 45 : null,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          labelStyle: const TextStyle(fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with search and select all
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Search users',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_filteredUsers.length} users • ${_selectedUserIds.length} selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Text(
                      'Select All',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Transform.scale(
                      scale: 0.9,
                      child: Checkbox(
                        value: _selectAll,
                        onChanged: _toggleSelectAll,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Users List
          Container(
            height: 300,
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                final isSelected = _selectedUserIds.contains(user.id);

                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[100]!, width: 1),
                    ),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      user.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      user.email,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    value: isSelected,
                    onChanged: (value) =>
                        _toggleUserSelection(user.id, value ?? false),
                    secondary: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.person, size: 18),
                    ),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              child: AppButton(
                onPressed: _sendToAllUsers,
                text: 'Send to All',
                variant: 'outline',
                loading: _sending,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 44,
              child: AppButton(
                onPressed: _sendNotification,
                text: 'Send to Selected',
                loading: _sending,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _imageUrlController.dispose();
    _dataController.dispose();
    super.dispose();
  }
}

class _DebugTools extends StatefulWidget {
  @override
  State<_DebugTools> createState() => _DebugToolsState();
}

class _DebugToolsState extends State<_DebugTools> {
  String? _token;
  bool _loading = false;

  Future<void> _loadToken() async {
    setState(() {
      _loading = true;
    });
    try {
      final t = await FirebaseMessaging.instance.getToken();
      setState(() {
        _token = t;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _requestPerms() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _localTest() async {
    await NotificationService().showLocalNotification(
      title: 'Test',
      body: 'Local heads-up',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Debug Tools',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildDebugButton(
                onPressed: _loadToken,
                label: _loading ? 'Loading...' : 'Show FCM Token',
                color: Colors.blue,
              ),
              _buildDebugButton(
                onPressed: _requestPerms,
                label: 'Request Permission',
                color: Colors.orange,
              ),
              _buildDebugButton(
                onPressed: _localTest,
                label: 'Local Test',
                color: Colors.green,
              ),
            ],
          ),
          if (_token != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                'Token: $_token',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                maxLines: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDebugButton({
    required VoidCallback onPressed,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label),
      ),
    );
  }
}