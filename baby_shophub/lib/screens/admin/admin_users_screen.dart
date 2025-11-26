import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/admin_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../utils/admin_utils.dart';

/* -------------------------------------------------
   1.  CONSTANTS
   ------------------------------------------------- */
class AppColors {
  static const Color primary = Color(0xFF6366F1); // indigo-500
  static const Color primaryDark = Color(0xFF4F46E5); // indigo-600
  static const Color secondary = Color(0xFFEC4899); // pink-500
  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color error = Color(0xFFEF4444); // red-500
  static const Color scaffold = Color(0xFFFAFAFA); // grey-50
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final UserService _userService = UserService();
  List<UserModel> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String _filterRole = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Animation & Scroll
  late AnimationController _animationController;
  late ScrollController _scrollCtrl;
  double _appBarOpacity = 0;

  // Bulk selection
  Set<String> _selectedUsers = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scrollCtrl = ScrollController()
      ..addListener(() {
        final offset = _scrollCtrl.offset;
        setState(() => _appBarOpacity = (offset / 120).clamp(0, 1));
        
        if (_scrollCtrl.position.pixels >=
                _scrollCtrl.position.maxScrollExtent - 200 &&
            !_isLoadingMore &&
            _hasMore) {
          _loadMoreUsers();
        }
      });
      
    _loadUsers();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _users = [];
        _isLoading = true;
        _hasMore = true;
        _lastDocument = null;
        _selectedUsers.clear();
        _isSelectionMode = false;
      });
    }

    try {
      final result = await _adminService.getUsersPaginated(
        limit: 20,
        startAfter: _lastDocument,
      );

      final users = result['users'] as List<UserModel>;
      final lastDocument = result['lastDocument'] as DocumentSnapshot?;

      if (!mounted) return;

      setState(() {
        if (refresh) {
          _users = users;
        } else {
          _users.addAll(users);
        }
        _isLoading = false;
        _isLoadingMore = false;
        _hasMore = users.length == 20;
        _lastDocument = lastDocument;
      });

      if (refresh) {
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      _showErrorSnackBar('Failed to load users: $e');
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await _loadUsers();
  }

  List<UserModel> get _filteredUsers {
    List<UserModel> filtered = _filterRole == 'all'
        ? _users
        : _users.where((user) => user.role == _filterRole).toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (user) =>
                user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                user.email.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return filtered;
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await AdminUtils.updateUserRole(userId, newRole);
      _showSuccessSnackBar('User role updated to ${newRole.toUpperCase()}');
      await _loadUsers(refresh: true);
    } catch (e) {
      _showErrorSnackBar('Failed to update user role: $e');
    }
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete $userName? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteUser(userId);
        _showSuccessSnackBar('User deleted successfully');
        await _loadUsers(refresh: true);
      } catch (e) {
        _showErrorSnackBar('Failed to delete user: $e');
      }
    }
  }

  Future<void> _bulkDeleteUsers() async {
    if (_selectedUsers.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Multiple Users'),
        content: Text(
          'Are you sure you want to delete ${_selectedUsers.length} users? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Future.wait(
          _selectedUsers.map((userId) => _adminService.deleteUser(userId)),
        );
        _showSuccessSnackBar(
          '${_selectedUsers.length} users deleted successfully',
        );
        setState(() {
          _selectedUsers.clear();
          _isSelectionMode = false;
        });
        await _loadUsers(refresh: true);
      } catch (e) {
        _showErrorSnackBar('Failed to delete users: $e');
      }
    }
  }

  Future<void> _bulkUpdateRole(String newRole) async {
    if (_selectedUsers.isEmpty) return;

    try {
      await Future.wait(
        _selectedUsers.map(
          (userId) => AdminUtils.updateUserRole(userId, newRole),
        ),
      );
      _showSuccessSnackBar(
        '${_selectedUsers.length} users updated to ${newRole.toUpperCase()}',
      );
      setState(() {
        _selectedUsers.clear();
        _isSelectionMode = false;
      });
      await _loadUsers(refresh: true);
    } catch (e) {
      _showErrorSnackBar('Failed to update users: $e');
    }
  }

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedUsers.contains(userId)) {
        _selectedUsers.remove(userId);
        if (_selectedUsers.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedUsers.add(userId);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedUsers.length == _filteredUsers.length) {
        _selectedUsers.clear();
        _isSelectionMode = false;
      } else {
        _selectedUsers = _filteredUsers.map((user) => user.id).toSet();
        _isSelectionMode = true;
      }
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showUserEditDialog(UserModel user) async {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone ?? '');
    String selectedRole = user.role;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Edit User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Update information for ${user.name}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: 'User Role',
                    ),
                    items: AdminUtils.getAvailableRoles().map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Row(
                          children: [
                            Icon(
                              _getRoleIcon(role),
                              size: 20,
                              color: _getRoleColor(role),
                            ),
                            const SizedBox(width: 12),
                            Text(role.toUpperCase()),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedRole = value ?? selectedRole;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            // Update user profile
                            final updatedUser = user.copyWith(
                              name: nameController.text.trim(),
                              email: emailController.text.trim(),
                              phone: phoneController.text.trim().isEmpty
                                  ? null
                                  : phoneController.text.trim(),
                            );

                            await _userService.updateUserProfile(updatedUser);

                            // Update role if changed
                            if (selectedRole != user.role) {
                              await AdminUtils.updateUserRole(
                                user.id,
                                selectedRole,
                              );
                            }

                            _showSuccessSnackBar('User updated successfully');
                            await _loadUsers(refresh: true);
                            Navigator.pop(context);
                          } catch (e) {
                            _showErrorSnackBar('Failed to update user: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Update'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'moderator':
        return Icons.verified_user;
      case 'user':
        return Icons.person;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.scaffold,
      body: Stack(
        children: [
          /* -------------  background wave  ------------- */
          Positioned.fill(
            child: AnimatedWaveBackground(opacity: _appBarOpacity),
          ),
          /* -------------  content  ------------- */
          CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              if (_isLoading)
                ..._buildShimmerSliver()
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildSearchAndFilter(),
                        const SizedBox(height: 24),
                        if (_isSelectionMode)
                          _buildBulkActions(),
                        const SizedBox(height: 16),
                        _buildUsersList(),
                        if (_isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: AppColors.card.withValues(alpha: _appBarOpacity),
          ),
        ),
      ),
      title: Text(
        _isSelectionMode
            ? '${_selectedUsers.length} selected'
            : 'Manage Users',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary),
              onPressed: () {
                setState(() {
                  _selectedUsers.clear();
                  _isSelectionMode = false;
                });
              },
            )
          : const BackButton(color: AppColors.textPrimary),
      actions: [
        if (_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.select_all, color: AppColors.primary),
            onPressed: _selectAll,
            tooltip: 'Select All',
          ),
          PopupMenuButton<String>(
            onSelected: (role) => _bulkUpdateRole(role),
            itemBuilder: (context) => AdminUtils.getAvailableRoles()
                .map(
                  (role) => PopupMenuItem(
                    value: role,
                    child: Text('Set as ${role.toUpperCase()}'),
                  ),
                )
                .toList(),
            icon: const Icon(Icons.edit, color: AppColors.primary),
            tooltip: 'Bulk Update Role',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _bulkDeleteUsers,
            tooltip: 'Delete Selected',
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => _loadUsers(refresh: true),
            tooltip: 'Refresh',
          ),
        ],
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.scaffold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          // Role Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All Users'),
                const SizedBox(width: 8),
                _buildFilterChip('admin', 'Admins'),
                const SizedBox(width: 8),
                _buildFilterChip('moderator', 'Moderators'),
                const SizedBox(width: 8),
                _buildFilterChip('user', 'Customers'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _filterRole == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterRole = selected ? filter : 'all';
        });
      },
      backgroundColor: AppColors.scaffold,
      selectedColor: AppColors.primary.withValues(alpha: .1),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildBulkActions() {
    return _NeuroCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            '${_selectedUsers.length} users selected',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: .5),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildUserCard(user),
        );
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    final isSelected = _selectedUsers.contains(user.id);
    
    return InkWell(
      onLongPress: () => _toggleSelection(user.id),
      onTap: _isSelectionMode ? () => _toggleSelection(user.id) : null,
      child: _NeuroCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Checkbox(
                  value: isSelected,
                  activeColor: AppColors.primary,
                  onChanged: (value) => _toggleSelection(user.id),
                ),
              ),
            CircleAvatar(
              radius: 24,
              backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
              child: Icon(
                _getRoleIcon(user.role),
                color: _getRoleColor(user.role),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: TextStyle(
                        color: _getRoleColor(user.role),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!_isSelectionMode)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showUserEditDialog(user);
                  } else if (value == 'delete') {
                    _deleteUser(user.id, user.name);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildShimmerSliver() => [
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ShimmerWidget.rect(height: 150, radius: 16),
      ),
    ),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ShimmerWidget.rect(height: 100, radius: 16),
      ),
    ),
  ];
}

/* -------------------------------------------------
   UI COMPONENTS (Copied from Dashboard for consistency)
   ------------------------------------------------- */

class _NeuroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _NeuroCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1F2937) : AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black54
                : AppColors.primary.withValues(alpha: .08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ShimmerWidget extends StatelessWidget {
  final double height;
  final double radius;
  const ShimmerWidget.rect({
    required this.height,
    required this.radius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class AnimatedWaveBackground extends StatelessWidget {
  final double opacity;
  const AnimatedWaveBackground({required this.opacity, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: opacity,
      child: CustomPaint(
        painter: _WavePainter(Theme.of(context).brightness),
        size: Size.infinite,
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Brightness brightness;
  const _WavePainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withValues(alpha: .15),
          AppColors.secondary.withValues(alpha: .1),
        ],
      ).createShader(Offset.zero & size);
    final path = Path()
      ..moveTo(0, size.height * .3)
      ..quadraticBezierTo(
        size.width * .25,
        size.height * .4,
        size.width * .5,
        size.height * .3,
      )
      ..quadraticBezierTo(
        size.width * .75,
        size.height * .2,
        size.width,
        size.height * .3,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
