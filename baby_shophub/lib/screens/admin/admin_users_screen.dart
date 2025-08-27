import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../utils/admin_utils.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _filterRole = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _adminService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    }
  }

  List<UserModel> get _filteredUsers {
    if (_filterRole == 'all') return _users;
    return _users.where((user) => user.role == _filterRole).toList();
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await AdminUtils.updateUserRole(userId, newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User role updated to $newRole')),
      );
      _loadUsers(); // Reload users
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user role: $e')),
      );
    }
  }

  Future<void> _showRoleDialog(UserModel user) async {
    final roles = AdminUtils.getAvailableRoles();
    String? selectedRole = user.role;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: DropdownButtonFormField<String>(
          value: selectedRole,
          items: roles.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(role.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            selectedRole = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (selectedRole != null && selectedRole != user.role) {
                _updateUserRole(user.id, selectedRole!);
              }
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildRoleFilter(),
          Expanded(
            child: _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilter() {
    final roles = ['all', ...AdminUtils.getAvailableRoles()];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: roles.map((role) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(role == 'all' ? 'All Users' : role.toUpperCase()),
              selected: _filterRole == role,
              onSelected: (selected) {
                setState(() {
                  _filterRole = selected ? role : 'all';
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUsersList() {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_filterRole == 'all' ? 'No users found' : 'No $_filterRole users'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user.profileImage != null
                  ? NetworkImage(user.profileImage!)
                  : const AssetImage('assets/images/placeholder.png') as ImageProvider,
            ),
            title: Text(user.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                Text('Role: ${user.role.toUpperCase()}'),
                Text('Joined: ${user.createdAt.toString().split(' ')[0]}'),
              ],
            ),
            trailing: DropdownButton<String>(
              value: user.role,
              items: AdminUtils.getAvailableRoles().map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role.toUpperCase()),
                );
              }).toList(),
              onChanged: (newRole) {
                if (newRole != null && newRole != user.role) {
                  _updateUserRole(user.id, newRole);
                }
              },
            ),
          ),
        );
      },
    );
  }
}