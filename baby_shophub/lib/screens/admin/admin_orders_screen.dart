import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../services/admin_service.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import '../../widgets/common/app_button.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final AdminService _adminService = AdminService();
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  String _filter = 'all';
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  Stream<List<Order>>? _ordersStream;
  bool _showBulkActions = false;
  Set<String> _selectedOrders = {};

  @override
  void initState() {
    super.initState();
    _ordersStream = _orderService.listenToAllOrders();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _adminService.getAllOrders();
      setState(() {
        _orders = orders;
        _updateFilteredOrders();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load orders: $e')));
    }
  }

  void _updateFilteredOrders() {
    _filteredOrders = _orders.where((order) {
      // Filter by status
      if (_filter != 'all' && order.status != _filter) return false;

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!order.id.toLowerCase().contains(query) &&
            !order.shippingAddress.fullName.toLowerCase().contains(query) &&
            !order.totalAmount.toString().contains(query)) {
          return false;
        }
      }

      // Filter by date range
      if (_dateRange != null) {
        if (order.orderDate.isBefore(_dateRange!.start) ||
            order.orderDate.isAfter(_dateRange!.end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _adminService.updateOrderStatus(orderId, status);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order status updated')));
      _loadOrders(); // Reload orders
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update order: $e')));
    }
  }

  Future<void> _processRefund(String orderId, double amount) async {
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Refund Amount: \$${amount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Refund Reason',
                hintText: 'e.g., Customer request, defective product',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isNotEmpty) {
                try {
                  await _adminService.processRefund(
                    orderId,
                    amount,
                    reasonController.text,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refund processed successfully'),
                    ),
                  );
                  _loadOrders();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to process refund: $e')),
                  );
                }
              }
            },
            child: const Text('Process Refund'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport() async {
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Report'),
        content: const Text('Choose report format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'csv'),
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'pdf'),
            child: const Text('PDF'),
          ),
        ],
      ),
    );

    if (format != null) {
      try {
        if (format == 'csv') {
          await _exportCsv();
        } else {
          await _exportPdf();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $e')),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Order Management Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Order ID', 'Customer', 'Status', 'Total', 'Date'],
                data: _filteredOrders
                    .map(
                      (order) => [
                        order.id.substring(order.id.length - 8),
                        order.shippingAddress.fullName,
                        order.status,
                        '\$${order.totalAmount.toStringAsFixed(2)}',
                        DateFormat('MM/dd/yyyy').format(order.orderDate),
                      ],
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _bulkUpdateStatus(String status) async {
    if (_selectedOrders.isEmpty) return;

    try {
      for (final orderId in _selectedOrders) {
        await _adminService.updateOrderStatus(orderId, status);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated ${_selectedOrders.length} orders to $status'),
        ),
      );
      _selectedOrders.clear();
      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update orders: $e')));
    }
  }

  Future<void> _addTrackingInfo(String orderId, String userId) async {
    final trackingController = TextEditingController();
    final carrierController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tracking Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: trackingController,
              decoration: const InputDecoration(
                labelText: 'Tracking Number',
                hintText: 'Enter tracking number',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: carrierController,
              decoration: const InputDecoration(
                labelText: 'Carrier',
                hintText: 'e.g., UPS, FedEx, USPS',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (trackingController.text.isNotEmpty &&
                  carrierController.text.isNotEmpty) {
                try {
                  await _orderService.addTrackingInfo(
                    orderId,
                    trackingController.text,
                    carrierController.text,
                    userId: userId,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tracking information added')),
                  );
                  _loadOrders();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add tracking: $e')),
                  );
                }
              }
            },
            child: const Text('Add Tracking'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: _ordersStream,
      initialData: _orders,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _orders = snapshot.data!;
          _updateFilteredOrders();
          _isLoading = false;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Order Management'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download),
                onPressed: _generateReport,
                tooltip: 'Generate Report',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildSearchAndFilters(),
                    if (_showBulkActions && _selectedOrders.isNotEmpty)
                      _buildBulkActions(),
                    Expanded(child: _buildOrdersList()),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search orders by ID, customer name, or amount...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _updateFilteredOrders();
              });
            },
          ),
          const SizedBox(height: 12),
          // Filters row
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', 'Pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Processing', 'Processing'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Shipped', 'Shipped'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Delivered', 'Delivered'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Cancelled', 'Cancelled'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Refunded', 'Refunded'),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.date_range),
                onPressed: _selectDateRange,
                tooltip: 'Filter by date',
              ),
              IconButton(
                icon: Icon(
                  _showBulkActions
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                ),
                onPressed: () {
                  setState(() {
                    _showBulkActions = !_showBulkActions;
                    if (!_showBulkActions) _selectedOrders.clear();
                  });
                },
                tooltip: 'Bulk actions',
              ),
            ],
          ),
          if (_dateRange != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Text(
                    'Date: ${DateFormat('MM/dd/yyyy').format(_dateRange!.start)} - ${DateFormat('MM/dd/yyyy').format(_dateRange!.end)}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      setState(() {
                        _dateRange = null;
                        _updateFilteredOrders();
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    return FilterChip(
      label: Text(label),
      selected: _filter == filter,
      onSelected: (selected) {
        setState(() {
          _filter = selected ? filter : 'all';
          _updateFilteredOrders();
        });
      },
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _updateFilteredOrders();
      });
    }
  }

  Widget _buildBulkActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Text('${_selectedOrders.length} selected'),
          const Spacer(),
          TextButton(
            onPressed: () => _bulkUpdateStatus('Processing'),
            child: const Text('Mark Processing'),
          ),
          TextButton(
            onPressed: () => _bulkUpdateStatus('Shipped'),
            child: const Text('Mark Shipped'),
          ),
          TextButton(
            onPressed: () => _bulkUpdateStatus('Delivered'),
            child: const Text('Mark Delivered'),
          ),
          TextButton(
            onPressed: () => _bulkUpdateStatus('Cancelled'),
            child: const Text('Cancel Orders'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey,
            ),
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
                    if (_showBulkActions)
                      Checkbox(
                        value: _selectedOrders.contains(order.id),
                        onChanged: (selected) {
                          setState(() {
                            if (selected ?? false) {
                              _selectedOrders.add(order.id);
                            } else {
                              _selectedOrders.remove(order.id);
                            }
                          });
                        },
                      ),
                    Expanded(
                      child: Text(
                        'Order #${order.id.substring(order.id.length - 8)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                Text(
                  'Date: ${DateFormat('MM/dd/yyyy HH:mm').format(order.orderDate)}',
                ),
                if (order.trackingNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tracking: ${order.trackingNumber} (${order.carrier ?? 'Unknown'})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ],
                if (order.status == 'Refunded') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Refunded: \$${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ],
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
            size: 'small',
          ),
        if (order.status == 'Processing') ...[
          AppButton(
            onPressed: () => _addTrackingInfo(order.id, order.userId),
            text: 'Add Tracking',
            variant: 'outline',
            size: 'small',
          ),
          AppButton(
            onPressed: () => _updateOrderStatus(order.id, 'Shipped'),
            text: 'Ship',
            variant: 'outline',
            size: 'small',
          ),
        ],
        if (order.status == 'Shipped')
          AppButton(
            onPressed: () => _updateOrderStatus(order.id, 'Delivered'),
            text: 'Deliver',
            variant: 'outline',
            size: 'small',
          ),
        if (order.canCancel)
          AppButton(
            onPressed: () => _updateOrderStatus(order.id, 'Cancelled'),
            text: 'Cancel',
            variant: 'outline',
            size: 'small',
          ),
        if (order.status == 'Delivered' || order.status == 'Shipped')
          AppButton(
            onPressed: () => _processRefund(order.id, order.totalAmount),
            text: 'Refund',
            variant: 'outline',
            size: 'small',
          ),
        // View Details Button
        AppButton(
          onPressed: () => _showOrderDetails(order),
          text: 'Details',
          variant: 'outline',
          size: 'small',
        ),
      ],
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Order Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Order ID',
                order.id.substring(order.id.length - 8),
              ),
              _buildDetailRow('Customer', order.shippingAddress.fullName),
              _buildDetailRow(
                'Email',
                order.shippingAddress.phone,
              ), // Assuming phone field contains email or adjust accordingly
              _buildDetailRow(
                'Total Amount',
                '\$${order.totalAmount.toStringAsFixed(2)}',
              ),
              _buildDetailRow('Status', order.status),
              _buildDetailRow(
                'Order Date',
                DateFormat('MM/dd/yyyy HH:mm').format(order.orderDate),
              ),
              if (order.deliveryDate != null)
                _buildDetailRow(
                  'Delivery Date',
                  DateFormat('MM/dd/yyyy HH:mm').format(order.deliveryDate!),
                ),
              if (order.trackingNumber != null) ...[
                _buildDetailRow('Tracking Number', order.trackingNumber!),
                _buildDetailRow('Carrier', order.carrier ?? 'Unknown'),
              ],
              const SizedBox(height: 16),
              Text('Items:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...order.items.map(
                (item) => ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: Text(item.productName),
                  subtitle: Text(
                    'Qty: ${item.quantity} • \$${item.productPrice.toStringAsFixed(2)} each',
                  ),
                  trailing: Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Shipping Address:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(order.shippingAddress.displayAddress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _exportCsv() async {
    final buffer = StringBuffer();
    buffer.writeln('Order ID,Customer,Status,Total,Date,Items,Tracking');
    for (final order in _filteredOrders) {
      buffer.writeln(
        '${order.id.substring(order.id.length - 8)},'
        '${order.shippingAddress.fullName},'
        '${order.status},'
        '${order.totalAmount.toStringAsFixed(2)},'
        '${DateFormat('MM/dd/yyyy HH:mm').format(order.orderDate)},'
        '${order.itemCount},'
        '${order.trackingNumber ?? 'N/A'}',
      );
    }

    // For web, we'll use a different approach since clipboard might not work
    try {
      // Try to save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/orders_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv',
      );
      await file.writeAsString(buffer.toString());

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV exported to: ${file.path}')));
    } catch (e) {
      // Fallback to clipboard
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CSV copied to clipboard')));
    }
  }
}
