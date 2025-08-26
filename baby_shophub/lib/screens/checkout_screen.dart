import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../widgets/common/app_button.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = OrderService();
  bool _isLoading = false;

  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null && user.addresses.isNotEmpty) {
      final address = user.defaultAddress;
      if (address != null) {
        _fullNameController.text = address.name;
        _phoneController.text = address.phone;
        _streetController.text = address.street;
        _cityController.text = address.city;
        _stateController.text = address.state;
        _zipCodeController.text = address.zipCode;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _buildCheckoutForm(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Processing your order...'),
        ],
      ),
    );
  }

  Widget _buildCheckoutForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            _buildOrderSummary(),
            const SizedBox(height: 24),

            // Shipping Address
            _buildAddressSection(),
            const SizedBox(height: 24),

            // Payment Method
            _buildPaymentSection(),
            const SizedBox(height: 32),

            // Place Order Button
            AppButton(
              onPressed: _placeOrder,
              text: 'Place Order - \$${widget.totalAmount.toStringAsFixed(2)}',
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...widget.cartItems.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.productName} x${item.quantity}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    item.formattedTotalPrice,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '\$${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shipping Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your street address';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
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
                        return 'Please enter your city';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      prefixIcon: Icon(Icons.map),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your state';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _zipCodeController,
              decoration: const InputDecoration(
                labelText: 'ZIP Code',
                prefixIcon: Icon(Icons.markunread_mailbox),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your ZIP code';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.credit_card, color: Colors.blue),
              title: Text('Credit/Debit Card'),
              subtitle: Text('Pay securely with your card'),
              trailing: Icon(Icons.radio_button_checked, color: Colors.blue),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.grey),
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay when you receive your order'),
              trailing: const Icon(Icons.radio_button_unchecked, color: Colors.grey),
              onTap: () {
                // Handle cash on delivery selection
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final cartProvider = Provider.of<CartProvider>(context, listen: false);

        if (authProvider.currentUser != null) {
          // Create shipping address
          final shippingAddress = ShippingAddress(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            fullName: _fullNameController.text,
            phone: _phoneController.text,
            street: _streetController.text,
            city: _cityController.text,
            state: _stateController.text,
            zipCode: _zipCodeController.text,
            country: 'USA',
            isDefault: true,
          );

          // Create order
          final order = Order(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: authProvider.currentUser!.id,
            items: widget.cartItems.map((item) => OrderItem(
              productId: item.productId,
              productName: item.productName,
              productPrice: item.productPrice,
              productImage: item.productImage,
              quantity: item.quantity,
            )).toList(),
            totalAmount: widget.totalAmount,
            status: 'Pending',
            shippingAddress: shippingAddress,
            orderDate: DateTime.now(),
            paymentMethod: 'Credit Card',
          );

          // Save order
          await _orderService.createOrder(order);

          // Clear cart
          await cartProvider.clearCart(authProvider.currentUser!.id);

          // Show success message
          Fluttertoast.showToast(
            msg: "Order placed successfully!",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );

          // Navigate to order confirmation
          Navigator.pushReplacementNamed(context, '/order-confirmation');
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Failed to place order: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
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
    _fullNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }
}