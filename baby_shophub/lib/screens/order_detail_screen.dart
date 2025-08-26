import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/loading_widget.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.order.id.substring(widget.order.id.length - 6)}'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const AppLoadingWidget()
          : _buildOrderDetails(),
    );
  }

  Widget _buildOrderDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Status
          _buildStatusSection(),
          const SizedBox(height: 24),

          // Order Items
          _buildItemsSection(),
          const SizedBox(height: 24),

          // Shipping Address
          _buildAddressSection(),
          const SizedBox(height: 24),

          // Order Summary
          _buildOrderSummary(),
          const SizedBox(height: 24),

          // Actions
          if (widget.order.canCancel || widget.order.canReorder)
            _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Status Timeline
            _buildStatusTimeline(),
            const SizedBox(height: 16),
            // Tracking Info
            if (widget.order.trackingNumber != null)
              _buildTrackingInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final statuses = [
      'Pending',
      'Confirmed',
      'Processing',
      'Shipped',
      'Delivered'
    ];

    final currentStatusIndex = statuses.indexOf(widget.order.status);
    final isCancelled = widget.order.status == 'Cancelled';

    if (isCancelled) {
      return const ListTile(
        leading: Icon(Icons.cancel, color: Colors.red),
        title: Text('Order Cancelled'),
        subtitle: Text('This order has been cancelled'),
      );
    }

    return Column(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isCompleted = index <= currentStatusIndex;
        final isCurrent = index == currentStatusIndex;

        return ListTile(
          leading: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? Colors.green : Colors.grey[300],
              border: Border.all(
                color: isCurrent ? Colors.green : Colors.transparent,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          title: Text(
            status,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCompleted ? Colors.green : Colors.grey,
            ),
          ),
          trailing: isCurrent ? const Icon(Icons.arrow_forward, size: 16) : null,
        );
      }).toList(),
    );
  }

  Widget _buildTrackingInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tracking Number',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  widget.order.trackingNumber!,
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                ),
                if (widget.order.carrier != null)
                  Text(
                    'Carrier: ${widget.order.carrier}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...widget.order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // Product Image
                  Container(
                    width: 60,
                    height: 60,
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
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${item.quantity}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  // Price
                  Text(
                    item.formattedTotalPrice,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
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
            Text(widget.order.shippingAddress.fullName), // Use fullName
            Text(widget.order.shippingAddress.phone),
            const SizedBox(height: 8),
            Text(widget.order.shippingAddress.street),
            Text(
              '${widget.order.shippingAddress.city}, ${widget.order.shippingAddress.state} ${widget.order.shippingAddress.zipCode}',
            ),
            Text(widget.order.shippingAddress.country),
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
            const SizedBox(height: 16),
            _buildSummaryRow('Subtotal', '\$${widget.order.totalAmount.toStringAsFixed(2)}'),
            _buildSummaryRow('Shipping', 'Free'),
            _buildSummaryRow('Tax', '\$0.00'),
            const Divider(),
            _buildSummaryRow(
              'Total',
              widget.order.formattedTotalAmount,
              isTotal: true,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow('Payment Method', widget.order.paymentMethod),
            _buildSummaryRow(
              'Order Date',
              DateFormat('MMM dd, yyyy - HH:mm').format(widget.order.orderDate),
            ),
            if (widget.order.deliveryDate != null)
              _buildSummaryRow(
                'Delivery Date',
                DateFormat('MMM dd, yyyy').format(widget.order.deliveryDate!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.black : Colors.grey,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? Colors.green : Colors.black,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (widget.order.canCancel)
          Expanded(
            child: AppButton(
              onPressed: _cancelOrder,
              text: 'Cancel Order',
              variant: 'outline',
            ),
          ),
        if (widget.order.canCancel && widget.order.canReorder)
          const SizedBox(width: 12),
        if (widget.order.canReorder)
          Expanded(
            child: AppButton(
              onPressed: _reorder,
              text: 'Reorder',
            ),
          ),
      ],
    );
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _orderService.cancelOrder(widget.order.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully')),
        );
        Navigator.pop(context); // Go back to orders list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel order: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reorder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final newOrder = await _orderService.reorder(
        widget.order.id,
        authProvider.currentUser!.id,
      );

      if (newOrder != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        Navigator.pop(context); // Go back to orders list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reorder: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}