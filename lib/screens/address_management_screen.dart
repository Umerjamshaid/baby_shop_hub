import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/common/app_button.dart';
import 'add_edit_address_screen.dart';

class AddressManagementScreen extends StatefulWidget {
  final UserModel user;

  const AddressManagementScreen({super.key, required this.user});

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  final UserService _userService = UserService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Addresses'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAddressList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditAddressScreen(
                user: widget.user,
                onAddressSaved: _refreshAddresses,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAddressList() {
    if (widget.user.addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No addresses yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first address to get started',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            AppButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditAddressScreen(
                      user: widget.user,
                      onAddressSaved: _refreshAddresses,
                    ),
                  ),
                );
              },
              text: 'Add Address',
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.user.addresses.length,
      itemBuilder: (context, index) {
        final address = widget.user.addresses[index];
        return _buildAddressCard(address);
      },
    );
  }

  Widget _buildAddressCard(Address address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (address.isDefault)
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
            if (address.isDefault) const SizedBox(height: 8),
            Text(
              address.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(address.phone),
            const SizedBox(height: 8),
            Text(
              address.street,
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              '${address.city}, ${address.state} ${address.zipCode}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditAddressScreen(
                          user: widget.user,
                          address: address,
                          onAddressSaved: _refreshAddresses,
                        ),
                      ),
                    );
                  },
                  child: const Text('Edit'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _deleteAddress(address.id),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                if (!address.isDefault) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _setDefaultAddress(address.id),
                    child: const Text('Set Default'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshAddresses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final updatedUser = await _userService.getUserById(widget.user.id);

      if (updatedUser != null) {
        await authProvider.updateProfile(updatedUser);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh addresses: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _userService.deleteAddress(widget.user.id, addressId);
        await _refreshAddresses();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete address: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setDefaultAddress(String addressId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Find the address and update it to default
      final address = widget.user.addresses.firstWhere((a) => a.id == addressId);
      final updatedAddress = address.copyWith(isDefault: true);

      await _userService.updateAddress(widget.user.id, updatedAddress);
      await _refreshAddresses();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default address updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set default address: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}