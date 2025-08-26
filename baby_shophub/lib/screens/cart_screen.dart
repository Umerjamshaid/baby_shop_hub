import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/app_button.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shopping Cart',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          if (cartProvider.cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                _showClearCartDialog(cartProvider, authProvider);
              },
            ),
        ],
      ),
      body: _buildBody(cartProvider, authProvider),
    );
  }

  Widget _buildBody(CartProvider cartProvider, AuthProvider authProvider) {
    if (cartProvider.isLoading) {
      return _buildLoadingState();
    }

    if (cartProvider.cartItems.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cartProvider.cartItems.length,
            itemBuilder: (context, index) {
              final item = cartProvider.cartItems[index];
              return _buildCartItem(item, cartProvider, authProvider);
            },
          ),
        ),
        _buildCheckoutSection(cartProvider, authProvider),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some items to get started',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          AppButton(
            onPressed: () {
              Navigator.pop(context);
            },
            text: 'Continue Shopping',
            variant: 'primary',
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    CartItem item,
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(item.productImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  if (item.size != null || item.color != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.size != null)
                          Text(
                            'Size: ${item.size!}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        if (item.color != null)
                          Text(
                            'Color: ${item.color!}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        const SizedBox(height: 4),
                      ],
                    ),

                  Text(
                    item.formattedPrice,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity Controls
            Column(
              children: [
                // Quantity
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.quantity.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Quantity Buttons
                Row(
                  children: [
                    // Decrease Button
                    InkWell(
                      onTap: () {
                        if (item.quantity > 1) {
                          _updateQuantity(
                            cartProvider,
                            authProvider,
                            item.id,
                            item.quantity - 1,
                          );
                        } else {
                          _removeItem(cartProvider, authProvider, item.id);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.remove, size: 16),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Increase Button
                    InkWell(
                      onTap: () {
                        _updateQuantity(
                          cartProvider,
                          authProvider,
                          item.id,
                          item.quantity + 1,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.add, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Remove Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                _removeItem(cartProvider, authProvider, item.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200), // Fixed this line
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Order Summary
          _buildOrderSummary(cartProvider),
          const SizedBox(height: 16),

          // Checkout Button
          AppButton(
            onPressed: () {
              _proceedToCheckout(cartProvider, authProvider);
            },
            text: 'Proceed to Checkout',
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal', style: TextStyle(fontSize: 16)),
            Text(
              '\$${cartProvider.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Shipping', style: TextStyle(fontSize: 16)),
            const Text(
              'Free',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${cartProvider.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateQuantity(
    CartProvider cartProvider,
    AuthProvider authProvider,
    String itemId,
    int newQuantity,
  ) {
    if (authProvider.currentUser != null) {
      cartProvider.updateQuantity(
        authProvider.currentUser!.id,
        itemId,
        newQuantity,
      );
    }
  }

  void _removeItem(
    CartProvider cartProvider,
    AuthProvider authProvider,
    String itemId,
  ) {
    if (authProvider.currentUser != null) {
      cartProvider.removeFromCart(authProvider.currentUser!.id, itemId);

      Fluttertoast.showToast(
        msg: "Item removed from cart",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _showClearCartDialog(
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (authProvider.currentUser != null) {
                cartProvider.clearCart(authProvider.currentUser!.id);
                Navigator.pop(context);

                Fluttertoast.showToast(
                  msg: "Cart cleared",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout(
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    if (authProvider.currentUser == null) {
      Fluttertoast.showToast(
        msg: "Please login to proceed to checkout",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: cartProvider.cartItems,
          totalAmount: cartProvider.totalAmount,
        ),
      ),
    );
  }
}
