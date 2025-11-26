import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../services/admin_service.dart';
import '../../services/product_service.dart';

/* -------------------------------------------------
   1.  CONSTANTS – change only here for re-skin
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

/* -------------------------------------------------
   2.  MAIN SCREEN
   ------------------------------------------------- */
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  /* -------------------------------------------------
     2-a  Animation & scroll stuff
     ------------------------------------------------- */
  late AnimationController _animationController;
  late ScrollController _scrollCtrl;
  bool _isLoading = false;
  double _appBarOpacity = 0;

  final AdminService _adminService = AdminService();
  final ProductService _productService = ProductService();

  // Report state
  String _selectedReportType = 'sales';
  String _selectedTimeRange = '30d';
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic> _reportData = {};

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
    _generateReport();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);

    try {
      final orders = await _adminService.getAllOrders();
      final products = await _productService.getAllProducts();

      final filteredOrders = _filterOrdersByDate(orders);

      switch (_selectedReportType) {
        case 'sales':
          _reportData = _generateSalesReport(filteredOrders, products);
          break;
        case 'products':
          _reportData = _generateProductReport(filteredOrders, products);
          break;
        case 'customers':
          _reportData = _generateCustomerReport(filteredOrders);
          break;
        case 'inventory':
          _reportData = _generateInventoryReport(products);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Order> _filterOrdersByDate(List<Order> orders) {
    if (_startDate == null && _endDate == null) {
      // Default to last 30 days if no date range specified
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      return orders
          .where((order) => order.orderDate.isAfter(thirtyDaysAgo))
          .toList();
    }

    return orders.where((order) {
      bool afterStart =
          _startDate == null || order.orderDate.isAfter(_startDate!);
      bool beforeEnd =
          _endDate == null ||
          order.orderDate.isBefore(_endDate!.add(const Duration(days: 1)));
      return afterStart && beforeEnd;
    }).toList();
  }

  Map<String, dynamic> _generateSalesReport(
    List<Order> orders,
    List<Product> products,
  ) {
    final totalRevenue = orders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );
    final totalOrders = orders.length;
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

    // Sales by category
    final categorySales = <String, double>{};
    for (final order in orders) {
      for (final item in order.items) {
        final product = products.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => Product(
            id: item.productId,
            name: 'Unknown Product',
            description: '',
            price: 0,
            unit: 'item',
            taxRate: 0.0,
            category: 'Unknown',
            sku: null,
            stockQuantity: 0,
            isService: false,
            isActive: true,
            imageUrls: [],
            brand: 'Unknown',
            ageRange: 'Unknown',
            rating: 0,
            reviewCount: 0,
            isFeatured: false,
            sizes: [],
            colors: [],
            materials: [],
            isEcoFriendly: false,
            isOrganic: false,
            discountPercentage: 0,
            weight: null,
            length: null,
            width: null,
            height: null,
            tags: [],
            warranty: null,
            originCountry: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        categorySales[product.category] =
            (categorySales[product.category] ?? 0) + item.totalPrice;
      }
    }

    // Daily sales
    final dailySales = <DateTime, double>{};
    for (final order in orders) {
      final date = DateTime(
        order.orderDate.year,
        order.orderDate.month,
        order.orderDate.day,
      );
      dailySales[date] = (dailySales[date] ?? 0) + order.totalAmount;
    }

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'avgOrderValue': avgOrderValue,
      'categorySales': categorySales,
      'dailySales': dailySales,
    };
  }

  Map<String, dynamic> _generateProductReport(
    List<Order> orders,
    List<Product> products,
  ) {
    final productStats = <String, Map<String, dynamic>>{};

    for (final order in orders) {
      for (final item in order.items) {
        final productId = item.productId;
        productStats[productId] ??= {
          'quantity': 0,
          'revenue': 0.0,
          'orders': 0,
        };
        productStats[productId]!['quantity'] += item.quantity;
        productStats[productId]!['revenue'] += item.totalPrice;
        productStats[productId]!['orders'] += 1;
      }
    }

    // Add product details
    final detailedStats = <Map<String, dynamic>>[];
    for (final entry in productStats.entries) {
      final product = products.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => Product(
          id: entry.key,
          name: 'Unknown Product',
          description: '',
          price: 0,
          unit: 'item',
          taxRate: 0.0,
          category: 'Unknown',
          sku: null,
          stockQuantity: 0,
          isService: false,
          isActive: true,
          imageUrls: [],
          brand: 'Unknown',
          ageRange: 'Unknown',
          rating: 0,
          reviewCount: 0,
          isFeatured: false,
          sizes: [],
          colors: [],
          materials: [],
          isEcoFriendly: false,
          isOrganic: false,
          discountPercentage: 0,
          weight: null,
          length: null,
          width: null,
          height: null,
          tags: [],
          warranty: null,
          originCountry: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      detailedStats.add({'product': product, 'stats': entry.value});
    }

    // Sort by revenue
    detailedStats.sort(
      (a, b) => (b['stats']['revenue'] as double).compareTo(
        a['stats']['revenue'] as double,
      ),
    );

    return {
      'productStats': detailedStats.take(20).toList(), // Top 20 products
      'totalProductsSold': productStats.length,
    };
  }

  Map<String, dynamic> _generateCustomerReport(List<Order> orders) {
    final customerStats = <String, Map<String, dynamic>>{};

    for (final order in orders) {
      final userId = order.userId;
      customerStats[userId] ??= {
        'totalSpent': 0.0,
        'orderCount': 0,
        'lastOrder': order.orderDate,
        'firstOrder': order.orderDate,
      };

      customerStats[userId]!['totalSpent'] += order.totalAmount;
      customerStats[userId]!['orderCount'] += 1;

      if (order.orderDate.isAfter(customerStats[userId]!['lastOrder'])) {
        customerStats[userId]!['lastOrder'] = order.orderDate;
      }
      if (order.orderDate.isBefore(customerStats[userId]!['firstOrder'])) {
        customerStats[userId]!['firstOrder'] = order.orderDate;
      }
    }

    final topCustomers = customerStats.entries.toList()
      ..sort(
        (a, b) => (b.value['totalSpent'] as double).compareTo(
          a.value['totalSpent'] as double,
        ),
      );

    return {
      'topCustomers': topCustomers.take(20).toList(),
      'totalCustomers': customerStats.length,
      'avgCustomerValue': customerStats.isNotEmpty
          ? customerStats.values.fold<double>(
                  0,
                  (sum, stats) => sum + stats['totalSpent'],
                ) /
                customerStats.length
          : 0,
    };
  }

  Map<String, dynamic> _generateInventoryReport(List<Product> products) {
    final lowStock = products.where((p) => p.stock <= 5).toList();
    final outOfStock = products.where((p) => p.stock == 0).toList();
    final totalValue = products.fold<double>(
      0,
      (sum, p) => sum + (p.price * p.stock),
    );

    final categoryStock = <String, Map<String, dynamic>>{};
    for (final product in products) {
      categoryStock[product.category] ??= {
        'totalStock': 0,
        'totalValue': 0.0,
        'productCount': 0,
      };
      categoryStock[product.category]!['totalStock'] += product.stock;
      categoryStock[product.category]!['totalValue'] +=
          product.price * product.stock;
      categoryStock[product.category]!['productCount'] += 1;
    }

    return {
      'lowStock': lowStock,
      'outOfStock': outOfStock,
      'totalValue': totalValue,
      'categoryStock': categoryStock,
      'totalProducts': products.length,
    };
  }

  /* -------------------------------------------------
     2-b  Build
     ------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _buildReportControls(),
                ),
              ),
              if (_isLoading)
                ..._buildShimmerSliver()
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: _buildReportContent(),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------
     2-c  Sliver AppBar (glass)
     ------------------------------------------------- */
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
        'Reports',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
    );
  }

  /* -------------------------------------------------
     2-d  Report controls
     ------------------------------------------------- */
  Widget _buildReportControls() {
    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Configuration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          // Report Type
          const Text(
            'Report Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildReportTypeChip('Sales', 'sales'),
              const SizedBox(width: 8),
              _buildReportTypeChip('Products', 'products'),
              const SizedBox(width: 8),
              _buildReportTypeChip('Customers', 'customers'),
              const SizedBox(width: 8),
              _buildReportTypeChip('Inventory', 'inventory'),
            ],
          ),
          const SizedBox(height: 20),
          // Date Range
          const Text(
            'Date Range',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: 'Start Date',
                  date: _startDate,
                  onChanged: (date) => setState(() => _startDate = date),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker(
                  label: 'End Date',
                  date: _endDate,
                  onChanged: (date) => setState(() => _endDate = date),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateReport,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.analytics),
              label: Text(_isLoading ? 'Generating...' : 'Generate Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeChip(String label, String type) {
    final isSelected = _selectedReportType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedReportType = type);
        }
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

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required Function(DateTime?) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: .2),
          ),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.card,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? '${date.month}/${date.day}/${date.year}' : label,
                style: TextStyle(
                  color: date != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* -------------------------------------------------
     2-e  Report content
     ------------------------------------------------- */
  Widget _buildReportContent() {
    switch (_selectedReportType) {
      case 'sales':
        return _buildSalesReport();
      case 'products':
        return _buildProductReport();
      case 'customers':
        return _buildCustomerReport();
      case 'inventory':
        return _buildInventoryReport();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSalesReport() {
    final data = _reportData;
    final totalRevenue = data['totalRevenue'] ?? 0.0;
    final totalOrders = data['totalOrders'] ?? 0;
    final avgOrderValue = data['avgOrderValue'] ?? 0.0;
    final categorySales = data['categorySales'] as Map<String, double>? ?? {};
    final dailySales = data['dailySales'] as Map<DateTime, double>? ?? {};

    return Column(
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Revenue',
                '\$${totalRevenue.toStringAsFixed(2)}',
                Icons.trending_up,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Orders',
                totalOrders.toString(),
                Icons.shopping_cart,
                AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Avg Order Value',
                '\$${avgOrderValue.toStringAsFixed(2)}',
                Icons.attach_money,
                AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Categories',
                categorySales.length.toString(),
                Icons.category,
                AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Sales Trend Chart
        if (dailySales.isNotEmpty)
          _NeuroCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sales Trend',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.textSecondary.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final dates = dailySales.keys.toList()..sort();
                              if (value.toInt() >= 0 && value.toInt() < dates.length) {
                                final date = dates[value.toInt()];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${date.month}/${date.day}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '\$${value.toInt()}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (dailySales.length - 1).toDouble(),
                      minY: 0,
                      maxY: dailySales.values.reduce((a, b) => a > b ? a : b) * 1.2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: () {
                            final sortedEntries = dailySales.entries.toList()
                              ..sort((a, b) => a.key.compareTo(b.key));
                            return sortedEntries.asMap().entries.map((entry) {
                              return FlSpot(
                                entry.key.toDouble(),
                                entry.value.value,
                              );
                            }).toList();
                          }(),
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.secondary,
                            ],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.2),
                                AppColors.secondary.withOpacity(0.05),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        // Category Pie Chart
        if (categorySales.isNotEmpty)
          _NeuroCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sales by Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _buildPieChartSections(categorySales, totalRevenue),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...categorySales.entries.map((entry) {
                  final percentage = totalRevenue > 0
                      ? (entry.value / totalRevenue) * 100
                      : 0;
                  final color = _getCategoryColor(categorySales.keys.toList().indexOf(entry.key));
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '\$${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<String, double> categorySales,
    double totalRevenue,
  ) {
    final categories = categorySales.entries.toList();
    return categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final percentage = totalRevenue > 0 ? (category.value / totalRevenue) * 100 : 0;
      
      return PieChartSectionData(
        color: _getCategoryColor(index),
        value: category.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      const Color(0xFF8B5CF6), // purple
      const Color(0xFF06B6D4), // cyan
      const Color(0xFFF97316), // orange
    ];
    return colors[index % colors.length];
  }

  Widget _buildProductReport() {
    final data = _reportData;
    final productStats =
        data['productStats'] as List<Map<String, dynamic>>? ?? [];
    final totalProductsSold = data['totalProductsSold'] ?? 0;

    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Performing Products',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalProductsSold products sold',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...productStats.map((item) {
            final product = item['product'] as Product;
            final stats = item['stats'] as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.scaffold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: product.firstImage.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.firstImage),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: product.firstImage.isEmpty
                          ? Colors.grey[200]
                          : null,
                    ),
                    child: product.firstImage.isEmpty
                        ? Icon(Icons.image, color: Colors.grey[500], size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${stats['quantity']} sold • ${stats['orders']} orders • \$${stats['revenue'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCustomerReport() {
    final data = _reportData;
    final topCustomers =
        data['topCustomers'] as List<MapEntry<String, Map<String, dynamic>>>? ??
        [];
    final totalCustomers = data['totalCustomers'] ?? 0;
    final avgCustomerValue = data['avgCustomerValue'] ?? 0.0;

    return Column(
      children: [
        // Summary
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Customers',
                totalCustomers.toString(),
                Icons.people,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Avg Customer Value',
                '\$${avgCustomerValue.toStringAsFixed(2)}',
                Icons.trending_up,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Top Customers
        _NeuroCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top Customers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...topCustomers.map((entry) {
                final userId = entry.key;
                final stats = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.scaffold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: .1,
                        ),
                        child: Text(
                          userId.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer ${userId.substring(0, 8)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${stats['orderCount']} orders • \$${stats['totalSpent'].toStringAsFixed(2)} spent',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryReport() {
    final data = _reportData;
    final lowStock = data['lowStock'] as List<Product>? ?? [];
    final outOfStock = data['outOfStock'] as List<Product>? ?? [];
    final totalValue = data['totalValue'] ?? 0.0;
    final totalProducts = data['totalProducts'] ?? 0;

    return Column(
      children: [
        // Summary
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Inventory Value',
                '\$${totalValue.toStringAsFixed(0)}',
                Icons.inventory,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Products',
                totalProducts.toString(),
                Icons.category,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Low Stock',
                lowStock.length.toString(),
                Icons.warning,
                AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Out of Stock',
                outOfStock.length.toString(),
                Icons.error,
                AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Low Stock Alert
        if (lowStock.isNotEmpty)
          _NeuroCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Low Stock Alert',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ...lowStock.take(5).map((product) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${product.stock} left',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------
     2-f  Helpers
     ------------------------------------------------- */
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
        child: ShimmerWidget.rect(height: 300, radius: 16),
      ),
    ),
  ];
}

/* ==========================================================
   3.  SMALL UI COMPONENTS
   ========================================================== */

/* -------------  neuro-card  ------------- */
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

/* -------------  shimmer skeleton  ------------- */
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

/* -------------  animated wave background  ------------- */
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
