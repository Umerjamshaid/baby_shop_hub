import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/common/app_button.dart';

class AddEditAddressScreen extends StatefulWidget {
  final UserModel user;
  final Address? address;
  final Function() onAddressSaved;

  const AddEditAddressScreen({
    super.key,
    required this.user,
    this.address,
    required this.onAddressSaved,
  });

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill form if editing existing address
    if (widget.address != null) {
      _nameController.text = widget.address!.name;
      _phoneController.text = widget.address!.phone;
      _streetController.text = widget.address!.street;
      _cityController.text = widget.address!.city;
      _stateController.text = widget.address!.state;
      _zipCodeController.text = widget.address!.zipCode;
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAddressForm(),
    );
  }

  Widget _buildAddressForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Field
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Street Field
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter street address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // City and State
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter city';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      prefixIcon: Icon(Icons.map),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter state';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ZIP Code
            TextFormField(
              controller: _zipCodeController,
              decoration: const InputDecoration(
                labelText: 'ZIP Code',
                prefixIcon: Icon(Icons.markunread_mailbox),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter ZIP code';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Default Address Checkbox
            CheckboxListTile(
              title: const Text('Set as default address'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value ?? false;
                });
              },
            ),
            const SizedBox(height: 32),

            // Save Button
            AppButton(
              onPressed: _saveAddress,
              text: widget.address == null ? 'Add Address' : 'Update Address',
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final address = Address(
          id: widget.address?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          zipCode: _zipCodeController.text.trim(),
          isDefault: _isDefault,
        );

        if (widget.address == null) {
          // Add new address
          await _userService.addAddress(widget.user.id, address);
        } else {
          // Update existing address
          await _userService.updateAddress(widget.user.id, address);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.address == null
                ? 'Address added successfully'
                : 'Address updated successfully'),
          ),
        );

        widget.onAddressSaved();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }
}