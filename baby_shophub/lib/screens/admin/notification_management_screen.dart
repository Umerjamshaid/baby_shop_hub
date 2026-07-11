import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart' as awesome;

import '../../services/user_service.dart';
import '../../services/notification_service.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../widgets/common/app_button.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

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
  final ProductService _productService = ProductService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _productSearchController =
      TextEditingController();

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  Set<String> _selectedUserIds = {};
  bool _selectAll = false;
  bool _sendToAll = false;
  bool _isLoading = false;
  bool _sending = false;
  String _selectedType = 'general'; // general, product, order, promotion
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
    _loadProducts();
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

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getAllProducts();
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
      });
    } catch (e) {
      // ignore silently; product sending still works via manual JSON
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
      // Build payload automatically from UI selections
      Map<String, dynamic>? extraData;
      if (_selectedType == 'product' && _selectedProduct != null) {
        extraData = {'type': 'product', 'productId': _selectedProduct!.id};
        if (_imageUrlController.text.trim().isEmpty) {
          _imageUrlController.text = _selectedProduct!.firstImage;
        }
      } else if (_dataController.text.trim().isNotEmpty) {
        // Fallback: advanced JSON if provided
        try {
          final parsed = jsonDecode(_dataController.text.trim());
          if (parsed is Map<String, dynamic>) {
            extraData = parsed;
          }
        } catch (_) {}
      } else {
        extraData = {'type': _selectedType};
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
        _selectedType = 'general';
        _selectedProduct = null;
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
            // Type selector
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Notification Type',
                prefixIcon: const Icon(Icons.category, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'general', child: Text('General')),
                DropdownMenuItem(value: 'product', child: Text('Product')),
                DropdownMenuItem(value: 'promotion', child: Text('Promotion')),
                DropdownMenuItem(value: 'order', child: Text('Order')),
              ],
              onChanged: (v) => setState(() => _selectedType = v ?? 'general'),
            ),
            const SizedBox(height: 10),
            if (_selectedType == 'product') _buildProductPicker(),
            if (_selectedType == 'product') const SizedBox(height: 10),
            _buildCompactTextField(
              controller: _imageUrlController,
              label: 'Image URL (optional)',
              icon: Icons.image,
            ),
            const SizedBox(height: 8),
            if (_imageUrlController.text.trim().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _imageUrlController.text.trim(),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    alignment: Alignment.center,
                    color: Colors.grey[200],
                    child: const Text('Invalid image URL'),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            // Advanced JSON (optional)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Advanced Payload (optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const _PayloadTutorialModal(),
                      );
                    },
                    icon: const Icon(Icons.help_outline, size: 16),
                    label: const Text('Help'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              children: [
                const SizedBox(height: 8),
                _buildCompactTextField(
                  controller: _dataController,
                  label: 'Payload (JSON)',
                  icon: Icons.data_object,
                  hintText: '{"type":"offer","id":"123"}',
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Need help with payloads? Click "Help" above for examples and testing.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
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
    return SizedBox(
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
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
                      child: SizedBox(
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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
          SizedBox(
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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

  Widget _buildProductPicker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Product',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _productSearchController,
                      onChanged: (q) {
                        final query = q.toLowerCase();
                        setState(() {
                          _filteredProducts = _allProducts.where((p) {
                            return p.name.toLowerCase().contains(query);
                          }).toList();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search product by name',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: _allProducts.isEmpty
                        ? null
                        : () async {
                            final selected = await showDialog<Product>(
                              context: context,
                              builder: (context) {
                                return Dialog(
                                  insetPadding: const EdgeInsets.all(16),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 420,
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          child: const Text(
                                            'Pick a Product',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const Divider(height: 1),
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: _filteredProducts.length,
                                            itemBuilder: (context, index) {
                                              final p =
                                                  _filteredProducts[index];
                                              return ListTile(
                                                leading: SizedBox(
                                                  width: 40,
                                                  height: 40,
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    child:
                                                        p.firstImage.startsWith(
                                                          'http',
                                                        )
                                                        ? Image.network(
                                                            p.firstImage,
                                                            width: 40,
                                                            height: 40,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  _,
                                                                  __,
                                                                  ___,
                                                                ) => Container(
                                                                  color: Colors
                                                                      .grey[200],
                                                                  child: const Icon(
                                                                    Icons.image,
                                                                    size: 18,
                                                                  ),
                                                                ),
                                                          )
                                                        : Container(
                                                            color: Colors
                                                                .grey[200],
                                                            child: const Icon(
                                                              Icons.image,
                                                              size: 18,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                                title: Text(
                                                  p.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  p.formattedPrice,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                onTap: () =>
                                                    Navigator.pop(context, p),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                            if (selected != null) {
                              setState(() {
                                _selectedProduct = selected;
                                if (_imageUrlController.text.trim().isEmpty) {
                                  _imageUrlController.text =
                                      selected.firstImage;
                                }
                              });
                            }
                          },
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Pick'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedProduct != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (_selectedProduct!.firstImage.startsWith('http')
                          ? Image.network(
                              _selectedProduct!.firstImage,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 20),
                              ),
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 20),
                            )),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedProduct!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedProduct!.formattedPrice,
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedProduct = null),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
            child: SizedBox(
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
            child: SizedBox(
              height: 44,
              child: AppButton(
                onPressed: _sendNotification,
                text: 'Send to Selected',
                loading: _sending,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 44,
              child: AppButton(
                onPressed: () async {
                  if (_titleController.text.isEmpty ||
                      _messageController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter title and message'),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _sending = true;
                  });
                  try {
                    final auth = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    if (auth.currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No logged-in user')),
                      );
                      return;
                    }
                    await _notificationService.sendNotificationToUsers(
                      title: _titleController.text,
                      message: _messageController.text,
                      userIds: [auth.currentUser!.id],
                      imageUrl: _imageUrlController.text.trim().isEmpty
                          ? null
                          : _imageUrlController.text.trim(),
                      data: const {'type': 'general'},
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification sent to yourself'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to send to self: $e')),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        _sending = false;
                      });
                    }
                  }
                },
                text: 'Send to Myself',
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

class _PayloadTutorialModal extends StatefulWidget {
  const _PayloadTutorialModal({super.key});

  @override
  State<_PayloadTutorialModal> createState() => _PayloadTutorialModalState();
}

class _PayloadTutorialModalState extends State<_PayloadTutorialModal> {
  String _selectedExample = 'general';
  final TextEditingController _testPayloadController = TextEditingController();
  bool _isTesting = false;

  final Map<String, Map<String, dynamic>> _payloadExamples = {
    'general': {
      'description': 'Basic notification without special actions',
      'payload': '{"type": "general"}',
      'explanation':
          'Simple notification that opens the home screen when tapped.',
    },
    'product': {
      'description': 'Product promotion with deep linking',
      'payload':
          '{"type": "product", "productId": "prod_12345", "imageUrl": "https://via.placeholder.com/400x300/FF6B6B/FFFFFF?text=Product+Image"}',
      'explanation':
          'Opens the specific product detail screen with image preview. Replace "prod_12345" with actual product ID and imageUrl with your product image.',
    },
    'order_update': {
      'description': 'Order status update notification',
      'payload':
          '{"type": "order_update", "orderId": "order_67890", "imageUrl": "https://via.placeholder.com/400x300/74B9FF/FFFFFF?text=Order+Update"}',
      'explanation':
          'Opens the order confirmation screen with status image. Use for shipping updates, delivery confirmations, etc.',
    },
    'promotion': {
      'description': 'Special offer or discount notification',
      'payload':
          '{"type": "promotion", "offerId": "promo_2024", "discount": "20%", "imageUrl": "https://via.placeholder.com/400x300/FDCB6E/000000?text=Special+Offer"}',
      'explanation':
          'Opens home screen with promotional content and discount image. Include discount details in payload.',
    },
    'cart_reminder': {
      'description': 'Abandoned cart reminder',
      'payload':
          '{"type": "cart_reminder", "items": "3", "total": "\$45.99", "imageUrl": "https://via.placeholder.com/400x300/FD79A8/FFFFFF?text=Cart+Reminder"}',
      'explanation':
          'Reminds users about items in their cart with cart image. Opens cart screen.',
    },
    'new_arrival': {
      'description': 'New product arrival announcement',
      'payload':
          '{"type": "new_arrival", "category": "baby_clothes", "count": "5", "imageUrl": "https://via.placeholder.com/400x300/00B894/FFFFFF?text=New+Arrival"}',
      'explanation':
          'Announces new products in a category with announcement image. Opens products list filtered by category.',
    },
  };

  @override
  void initState() {
    super.initState();
    _testPayloadController.text =
        _payloadExamples['general']!['payload'] as String;
  }

  Future<void> _testPayload() async {
    if (_testPayloadController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a payload to test')),
      );
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      Map<String, dynamic>? parsedPayload;
      try {
        parsedPayload =
            jsonDecode(_testPayloadController.text.trim())
                as Map<String, dynamic>?;
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid JSON format: $e')));
        return;
      }

      // Extract image URL from payload if present
      String? imageUrl;
      if (parsedPayload != null) {
        imageUrl = parsedPayload['imageUrl'] as String?;
      }

      // Send test notification with the payload and image
      await NotificationService().showLocalNotification(
        title: 'Payload Test',
        body: 'Testing your custom payload with image support',
        payload: parsedPayload?['type'] ?? 'general',
        imageUrl: imageUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Test notification sent! Check your device for image display.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Test failed: $e')));
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  void _loadExample(String type) {
    setState(() {
      _selectedExample = type;
      _testPayloadController.text =
          _payloadExamples[type]!['payload'] as String;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Notification Payload Tutorial',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Introduction
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📚 What are Notification Payloads?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Payloads are JSON data attached to notifications that tell the app what to do when the user taps the notification. They enable deep linking to specific screens and passing data.',
                            style: TextStyle(fontSize: 14, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Example Selection
                    const Text(
                      '🎯 Choose an Example:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _payloadExamples.entries.map((entry) {
                        final isSelected = _selectedExample == entry.key;
                        return FilterChip(
                          label: Text(
                            entry.key.replaceAll('_', ' ').toUpperCase(),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) _loadExample(entry.key);
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.2),
                          checkmarkColor: Theme.of(context).primaryColor,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Current Example Details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _payloadExamples[_selectedExample]!['description']
                                as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _payloadExamples[_selectedExample]!['explanation']
                                as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payload Editor
                    const Text(
                      '✏️ Edit Payload:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: _testPayloadController,
                      maxLines: 3,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      decoration: InputDecoration(
                        hintText: '{"type": "general"}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Test Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isTesting ? null : _testPayload,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isTesting ? 'Testing...' : '🚀 Try It!'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tips
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💡 Pro Tips:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Always include a "type" field to specify notification behavior\n'
                            '• Use meaningful IDs (productId, orderId, etc.) for deep linking\n'
                            '• Add "imageUrl" field for rich notifications with image previews\n'
                            '• Keep payloads small for better performance\n'
                            '• Test payloads before sending to all users\n'
                            '• Images are automatically downloaded and cached for system tray display',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _testPayloadController.dispose();
    super.dispose();
  }
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

  // Generate a safe notification ID within 32-bit integer range
  int _generateSafeNotificationId() {
    // Use current time in seconds (much smaller) combined with a hash
    final int timestamp =
        DateTime.now().millisecondsSinceEpoch ~/ 1000; // Convert to seconds
    final int hash = timestamp.hashCode.abs(); // Get positive hash
    // Ensure it fits within 32-bit signed integer range
    return hash % 0x7FFFFFFF; // Max 32-bit signed integer
  }

  Future<void> _forceTrayTest() async {
    try {
      // Generate a safe notification ID within 32-bit integer range
      final int nid = _generateSafeNotificationId();
      await awesome.AwesomeNotifications().createNotification(
        content: awesome.NotificationContent(
          id: nid,
          channelKey: 'order_updates',
          title: 'Tray Test',
          body:
              'This should appear in system tray even when app is background/terminated',
          notificationLayout: awesome.NotificationLayout.Default,
          payload: {'type': 'test'},
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tray test sent! Check system tray.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tray test failed: $e')));
    }
  }

  void _showPayloadTutorial() {
    showDialog(
      context: context,
      builder: (context) => const _PayloadTutorialModal(),
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
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
              _buildDebugButton(
                onPressed: _forceTrayTest,
                label: 'Force Tray Test',
                color: Colors.orange,
              ),
              _buildDebugButton(
                onPressed: _showPayloadTutorial,
                label: 'Payload Tutorial',
                color: Colors.purple,
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
