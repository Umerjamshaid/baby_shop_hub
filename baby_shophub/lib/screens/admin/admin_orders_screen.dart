import 'dart:ui';
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

/* -------------------------------------------------
   1.  CONSTANTS
   ------------------------------------------------- */
class AppColors {
  static const Color primary = Color(0xFF6366F1); // indigo-500
  static const Color primaryDark = Color(0xFF4F46E5); // indigo-600
  static const Color secondary = Color(0xFFEC4899); // pink-500
  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color error = Color(0xFFEF4444); // red-500
  static const Color scaffold = Color(0xFFFAFAFA); // grey-50
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
}

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
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

  late AnimationController _animationController;
  late ScrollController _scrollCtrl;
  double _appBarOpacity = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scrollCtrl = ScrollController()
      ..addListener(() {
        final offset = _scrollCtrl.offset;
        setState(() => _appBarOpacity = (offset / 120).clamp(0, 1));
      });
    _ordersStream = _orderService.listenToAllOrders();
    _loadOrders();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _adminService.getAllOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _updateFilteredOrders();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV copied to clipboard')),
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
          extendBodyBehindAppBar: true,
          backgroundColor: AppColors.scaffold,
          body: Stack(
            children: [
              /* -------------  background wave  ------------- */
              Positioned.fill(
                child: AnimatedWaveBackground(opacity: _appBarOpacity),
              ),
              /* -------------  content  ------------- */
              CustomScrollView(
                controller: _scrollCtrl,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  if (_isLoading)
                    ..._buildShimmerSliver()
                  else
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildSearchAndFilters(),
                            const SizedBox(height: 24),
                            if (_showBulkActions && _selectedOrders.isNotEmpty)
                              _buildBulkActions(),
                            const SizedBox(height: 16),
                            _buildOrdersList(),
                          ],
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: AppColors.card.withValues(alpha: _appBarOpacity),
          ),
        ),
      ),
      title: const Text(
        'Order Management',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.file_download),
            color: AppColors.primary,
            onPressed: _generateReport,
            tooltip: 'Generate Report',
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.scaffold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search orders...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _updateFilteredOrders();
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          // Filters row
          SingleChildScrollView(
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
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.date_range, color: AppColors.primary),
                onPressed: _selectDateRange,
                tooltip: 'Filter by date',
              ),
              if (_dateRange != null)
                Chip(
                  label: Text(
                    '${DateFormat('MM/dd').format(_dateRange!.start)} - ${DateFormat('MM/dd').format(_dateRange!.end)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onDeleted: () {
                    setState(() {
                      _dateRange = null;
                      _updateFilteredOrders();
                    });
                  },
                ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showBulkActions
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: AppColors.primary,
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
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _filter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = selected ? filter : 'all';
          _updateFilteredOrders();
        });
      },
      backgroundColor: AppColors.scaffold,
      selectedColor: AppColors.primary.withValues(alpha: .1),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _updateFilteredOrders();
      });
    }
  }

  Widget _buildBulkActions() {
    return _NeuroCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('${_selectedOrders.length} selected', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _bulkUpdateStatus,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Processing', child: Text('Mark Processing')),
              const PopupMenuItem(value: 'Shipped', child: Text('Mark Shipped')),
              const PopupMenuItem(value: 'Delivered', child: Text('Mark Delivered')),
              const PopupMenuItem(value: 'Cancelled', child: Text('Cancel Orders')),
            ],
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
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: .5),
            ),
            const SizedBox(height: 16),
            Text(
              _filter == 'all' ? 'No orders found' : 'No $_filter orders',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildOrderCard(order),
        );
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    return _NeuroCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_showBulkActions)
                Checkbox(
                  value: _selectedOrders.contains(order.id),
                  activeColor: AppColors.primary,
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(order.shippingAddress.fullName, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.attach_money, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('\$${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                DateFormat('MM/dd/yyyy HH:mm').format(order.orderDate),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          if (order.trackingNumber != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '${order.carrier ?? 'Carrier'}: ${order.trackingNumber}',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildOrderActions(order),
        ],
      ),
    );
  }

  Widget _buildOrderActions(Order order) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (order.status == 'Pending')
          _ActionButton(
            onPressed: () => _updateOrderStatus(order.id, 'Processing'),
            text: 'Process',
            color: AppColors.primary,
          ),
        if (order.status == 'Processing') ...[
          _ActionButton(
            onPressed: () => _addTrackingInfo(order.id, order.userId),
            text: 'Add Tracking',
            color: AppColors.secondary,
            isOutline: true,
          ),
          _ActionButton(
            onPressed: () => _updateOrderStatus(order.id, 'Shipped'),
            text: 'Ship',
            color: AppColors.success,
          ),
        ],
        if (order.status == 'Shipped')
          _ActionButton(
            onPressed: () => _updateOrderStatus(order.id, 'Delivered'),
            text: 'Deliver',
            color: AppColors.success,
          ),
        if (order.canCancel)
          _ActionButton(
            onPressed: () => _updateOrderStatus(order.id, 'Cancelled'),
            text: 'Cancel',
            color: AppColors.error,
            isOutline: true,
          ),
        if (order.status == 'Delivered' || order.status == 'Shipped')
          _ActionButton(
            onPressed: () => _processRefund(order.id, order.totalAmount),
            text: 'Refund',
            color: AppColors.warning,
            isOutline: true,
          ),
        // View Details Button
        _ActionButton(
          onPressed: () => _showOrderDetails(order),
          text: 'Details',
          color: AppColors.textSecondary,
          isOutline: true,
        ),
      ],
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Order Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Order ID', order.id.substring(order.id.length - 8)),
              _buildDetailRow('Customer', order.shippingAddress.fullName),
              _buildDetailRow('Phone', order.shippingAddress.phone),
              _buildDetailRow('Total Amount', '\$${order.totalAmount.toStringAsFixed(2)}'),
              _buildDetailRow('Status', order.status),
              _buildDetailRow('Order Date', DateFormat('MM/dd/yyyy HH:mm').format(order.orderDate)),
              if (order.deliveryDate != null)
                _buildDetailRow('Delivery Date', DateFormat('MM/dd/yyyy HH:mm').format(order.deliveryDate!)),
              if (order.trackingNumber != null) ...[
                _buildDetailRow('Tracking Number', order.trackingNumber!),
                _buildDetailRow('Carrier', order.carrier ?? 'Unknown'),
              ],
              const SizedBox(height: 24),
              const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...order.items.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.scaffold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              'Qty: ${item.quantity} • \$${item.productPrice.toStringAsFixed(2)} each',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text('\$${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Shipping Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.scaffold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(order.shippingAddress.displayAddress)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  List<Widget> _buildShimmerSliver() => [
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ShimmerWidget.rect(height: 200, radius: 16),
      ),
    ),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ShimmerWidget.rect(height: 120, radius: 16),
      ),
    ),
  ];
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color color;
  final bool isOutline;

  const _ActionButton({
    required this.onPressed,
    required this.text,
    required this.color,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutline) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(text),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
      ),
      child: Text(text),
    );
  }
}

/* -------------------------------------------------
   UI COMPONENTS (Copied from Dashboard for consistency)
   ------------------------------------------------- */

class _NeuroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _NeuroCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1F2937) : AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black54
                : AppColors.primary.withValues(alpha: .08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ShimmerWidget extends StatelessWidget {
  final double height;
  final double radius;
  const ShimmerWidget.rect({
    required this.height,
    required this.radius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class AnimatedWaveBackground extends StatelessWidget {
  final double opacity;
  const AnimatedWaveBackground({required this.opacity, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: opacity,
      child: CustomPaint(
        painter: _WavePainter(Theme.of(context).brightness),
        size: Size.infinite,
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Brightness brightness;
  const _WavePainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withValues(alpha: .15),
          AppColors.secondary.withValues(alpha: .1),
        ],
      ).createShader(Offset.zero & size);
    final path = Path()
      ..moveTo(0, size.height * .3)
      ..quadraticBezierTo(
        size.width * .25,
        size.height * .4,
        size.width * .5,
        size.height * .3,
      )
      ..quadraticBezierTo(
        size.width * .75,
        size.height * .2,
        size.width,
        size.height * .3,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
