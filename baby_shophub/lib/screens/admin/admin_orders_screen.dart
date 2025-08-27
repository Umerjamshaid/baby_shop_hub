import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../models/order_model.dart';
import '../../widgets/common/app_button.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final AdminService _adminService = AdminService();
  List<Order> _orders = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _adminService.getAllOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load orders: $e')),
      );
    }
  }

  List<Order> get _filteredOrders {
    if (_filter == 'all') return _orders;
    return _orders.where((order) => order.status == _filter).toList();
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _adminService.updateOrderStatus(orderId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order status updated')),
      );
      _loadOrders(); // Reload orders
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = {
      'all': 'All Orders',
      'Pending': 'Pending',
      'Processing': 'Processing',
      'Shipped': 'Shipped',
      'Delivered': 'Delivered',
      'Cancelled': 'Cancelled',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(entry.value),
              selected: _filter == entry.key,
              onSelected: (selected) {
                setState(() {
                  _filter = selected ? entry.key : 'all';
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_filter == 'all' ? 'No orders found' : 'No $_filter orders'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order #${order.id.substring(order.id.length - 6)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: order.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        order.status,
                        style: TextStyle(
                          color: order.statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Customer: ${order.shippingAddress.fullName}'),
                Text('Total: \$${order.totalAmount.toStringAsFixed(2)}'),
                Text('Items: ${order.itemCount}'),
                Text('Date: ${order.orderDate.toString().split(' ')[0]}'),
                const SizedBox(height: 12),
                _buildOrderActions(order),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderActions(Order order) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (order.status == 'Pending')
          AppButton(
            onPressed: () => _updateOrderStatus(order.id, 'Processing'),
            text: 'Process',
            variant: 'outline',
            size: 'small', // Now this will work
          ),
        if (order.status == 'Processing')
          AppButton(
            onPressed: () => _updateOrderStatus(order.id, 'Shipped'),
            text: 'Ship',
            variant: 'outline',
            size: 'small', // Now this will work
          ),
        if (order.status == 'Shipped')
          AppButton(
            onPressed: () => _updateOrderStatus(order.id, 'Delivered'),
            text: 'Deliver',
            variant: 'outline',
            size: 'small', // Now this will work
          ),
        if (order.canCancel)
          AppButton(
            onPressed: () => _updateOrderStatus(order.id, 'Cancelled'),
            text: 'Cancel',
            variant: 'outline',
            size: 'small', // Now this will work
            // color: Colors.red, // Remove this line or use it properly
          ),
      ],
    );
  }
}