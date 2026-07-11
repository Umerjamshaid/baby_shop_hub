import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart' as order_model;
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final order_model.Order order;
  final String? transactionId;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
    this.transactionId,
  });

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();

    // Send order confirmation notification
    _sendOrderConfirmationNotification();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildConfirmationContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Success Animation
          _buildSuccessAnimation(),
          const SizedBox(height: 30),

          // Order Details Card
          _buildOrderDetailsCard(),
          const SizedBox(height: 20),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_circle, size: 80, color: Colors.white),
    );
  }

  Widget _buildOrderDetailsCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Center(
              child: Text(
                'Order Confirmed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Thank you for your purchase',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),

            // Order Number
            _buildDetailRow(
              'Order Number',
              '#${widget.order.id.substring(widget.order.id.length - 8)}',
              Icons.receipt,
            ),
            const SizedBox(height: 12),

            // Transaction ID
            if (widget.transactionId != null)
              _buildDetailRow(
                'Transaction ID',
                widget.transactionId!,
                Icons.payment,
              ),
            if (widget.transactionId != null) const SizedBox(height: 12),

            // Order Date
            _buildDetailRow(
              'Order Date',
              DateFormat('MMM dd, yyyy - HH:mm').format(widget.order.orderDate),
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),

            // Payment Method
            _buildDetailRow(
              'Payment Method',
              _getPaymentMethodDisplayName(widget.order.paymentMethod),
              Icons.credit_card,
            ),
            const SizedBox(height: 12),

            // Total Amount
            _buildDetailRow(
              'Total Amount',
              '\$${widget.order.totalAmount.toStringAsFixed(2)}',
              Icons.attach_money,
              isTotal: true,
            ),
            const SizedBox(height: 20),

            // Order Items
            const Text(
              'Order Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...widget.order.items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(item.productImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Qty: ${item.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Delivery Information
            if (widget.order.deliveryDate != null) ...[
              const Text(
                'Delivery Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_shipping,
                      color: Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated Delivery',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy',
                            ).format(widget.order.deliveryDate!),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isTotal ? Colors.green : Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _trackOrder,
            icon: const Icon(Icons.track_changes),
            label: const Text('Track Order'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6C5CE7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _continueShopping,
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Continue Shopping'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.white),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodDisplayName(String paymentMethod) {
    switch (paymentMethod) {
      case 'credit_card':
        return 'Credit Card';
      case 'paypal':
        return 'PayPal';
      case 'apple_pay':
        return 'Apple Pay';
      case 'google_pay':
        return 'Google Pay';
      default:
        return paymentMethod;
    }
  }

  Future<void> _sendOrderConfirmationNotification() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId != null) {
        await _notificationService.showLocalNotification(
          title: 'Order Confirmed!',
          body:
              'Your order #${widget.order.id.substring(widget.order.id.length - 8)} has been placed successfully',
          payload: 'order_${widget.order.id}',
        );

        // Schedule delivery reminder if delivery date is available
        if (widget.order.deliveryDate != null) {
          final deliveryReminderDate = widget.order.deliveryDate!.subtract(
            const Duration(days: 1),
          );
          if (deliveryReminderDate.isAfter(DateTime.now())) {
            // In a real app, you'd schedule this with a background task
            // For now, we'll just show a local notification after a delay
            Future.delayed(const Duration(seconds: 5), () async {
              await _notificationService.showLocalNotification(
                title: 'Package arriving tomorrow!',
                body:
                    'Your order #${widget.order.id.substring(widget.order.id.length - 8)} will be delivered tomorrow',
                payload: 'order_${widget.order.id}',
              );
            });
          }
        }
      }
    } catch (e) {
      // Handle notification error silently
      debugPrint('Failed to send order confirmation notification: $e');
    }
  }

  void _trackOrder() {
    Navigator.pushNamed(
      context,
      '/order-tracking',
      arguments: {'order': widget.order},
    );
  }

  void _continueShopping() {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }
}
