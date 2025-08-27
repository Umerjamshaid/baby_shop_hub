import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../widgets/common/app_button.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'address_management_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(user: user),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
          ? _buildLoggedOutState()
          : _buildProfileContent(user, authProvider),
    );
  }

  // Build UI for logged-out users
  Widget _buildLoggedOutState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Welcome Illustration/Icon
          const Icon(Icons.person_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Welcome to BabyShopHub!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          const Text(
            'Create an account or sign in to manage your profile, save addresses, and track your orders.',
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Sign Up Button
          AppButton(
            onPressed: () {
              _navigateToRegister();
            },
            text: 'Create Account',
            width: double.infinity,
          ),
          const SizedBox(height: 16),

          // Login Button
          AppButton(
            onPressed: () {
              _navigateToLogin();
            },
            text: 'Sign In',
            variant: 'outline',
            width: double.infinity,
          ),
          const SizedBox(height: 16),

          // Guest continue shopping
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Continue as Guest',
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  // Build UI for logged-in users (your existing content)
  Widget _buildProfileContent(UserModel user, AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(user),
          const SizedBox(height: 24),

          // Account Info
          _buildAccountInfo(user),
          const SizedBox(height: 24),

          // Address Section
          _buildAddressSection(user),
          const SizedBox(height: 24),

          // Actions
          _buildActionButtons(authProvider),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: user.profileImage != null
                  ? NetworkImage(user.profileImage!)
                  : const AssetImage('assets/images/placeholder.png')
                        as ImageProvider,
              child: user.profileImage == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (user.phone != null) ...[
          const SizedBox(height: 8),
          Text(
            user.phone!,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          user.email,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAccountInfo(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Member since', _formatDate(user.createdAt)),
            const Divider(),
            _buildInfoRow('Email', user.email),
            if (user.phone != null) ...[
              const Divider(),
              _buildInfoRow('Phone', user.phone!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(UserModel user) {
    final defaultAddress = user.defaultAddress;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Addresses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddressManagementScreen(user: user),
                      ),
                    );
                  },
                  child: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (defaultAddress != null)
              _buildAddressCard(defaultAddress, true)
            else
              const Text(
                'No addresses added yet',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(Address address, bool isDefault) {
    return Card(
      color: isDefault ? Colors.blue[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DEFAULT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              address.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(address.phone),
            const SizedBox(height: 4),
            Text(
              address.fullAddress,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AuthProvider authProvider) {
    return Column(
      children: [
        AppButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddressManagementScreen(user: authProvider.currentUser!),
              ),
            );
          },
          text: 'Manage Addresses',
          variant: 'outline',
          width: double.infinity,
        ),
        const SizedBox(height: 12),
        AppButton(
          onPressed: _logout,
          text: 'Logout',
          variant: 'outline',
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logged out successfully')));

    // No need to navigate away - the UI will automatically update
    // to show the logged-out state because of the Provider rebuild
  }
}
