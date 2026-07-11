import 'dart:ui';
import 'package:flutter/material.dart';
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
class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  State<AdvancedAnalyticsScreen> createState() =>
      _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends State<AdvancedAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  /* -------------------------------------------------
     2-a  Animation & scroll stuff
     ------------------------------------------------- */
  late AnimationController _animationController;
  late ScrollController _scrollCtrl;
  bool _isLoading = true;
  double _appBarOpacity = 0;

  final AdminService _adminService = AdminService();
  final ProductService _productService = ProductService();
  Map<String, dynamic> _analyticsData = {};
  List<Order> _orders = [];
  List<Product> _products = [];
  String _selectedTimeRange = '7d';

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
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final orders = await _adminService.getAllOrders();
      final products = await _productService.getAllProducts();
      final stats = await _adminService.getDashboardStats();

      if (!mounted) return;
      setState(() {
        _orders = orders;
        _products = products;
        _analyticsData = stats;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load analytics: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
              if (_isLoading)
                ..._buildShimmerSliver()
              else
                ..._buildAnalyticsSlivers(),
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
        'Advanced Analytics',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.primary,
            onPressed: () {
              _animationController.reset();
              _loadAnalyticsData();
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTimeRange,
              items: const [
                DropdownMenuItem(value: '7d', child: Text('7 Days')),
                DropdownMenuItem(value: '30d', child: Text('30 Days')),
                DropdownMenuItem(value: '90d', child: Text('90 Days')),
              ],
              onChanged: (value) {
                setState(() => _selectedTimeRange = value!);
              },
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
              underline: const SizedBox(),
            ),
          ),
        ),
      ],
    );
  }

  /* -------------------------------------------------
     2-d  Analytics content
     ------------------------------------------------- */
  List<Widget> _buildAnalyticsSlivers() {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _buildKeyMetrics(),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _buildRevenueChart(),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _buildProductPerformance(),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _buildCustomerInsights(),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _buildInventoryAnalytics(),
        ),
      ),
    ];
  }

  Widget _buildKeyMetrics() {
    final totalRevenue = _orders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );
    final totalOrders = _orders.length;
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;
    final conversionRate = totalOrders > 0
        ? (totalOrders / (_analyticsData['totalUsers'] ?? 1)) * 100
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Revenue',
                '\$${totalRevenue.toStringAsFixed(2)}',
                Icons.trending_up,
                AppColors.success,
                '+12.5%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Total Orders',
                totalOrders.toString(),
                Icons.shopping_cart,
                AppColors.primary,
                '+8.2%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Avg Order Value',
                '\$${avgOrderValue.toStringAsFixed(2)}',
                Icons.attach_money,
                AppColors.warning,
                '+5.1%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Conversion Rate',
                '${conversionRate.toStringAsFixed(1)}%',
                Icons.people,
                AppColors.secondary,
                '+3.7%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final days = _selectedTimeRange == '7d'
        ? 7
        : _selectedTimeRange == '30d'
        ? 30
        : 90;
    final revenueData = _calculateRevenueOverTime(days);

    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Trend ($_selectedTimeRange)',
                style: const TextStyle(
                  fontSize: 18,
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
                  'Last $days days',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _RevenueChartPainter(revenueData),
              size: const Size(double.infinity, 200),
            ),
          ),
        ],
      ),
    );
  }

  Map<DateTime, double> _calculateRevenueOverTime(int days) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final map = <DateTime, double>{};

    for (int i = 0; i < days; i++) {
      final date = start.add(Duration(days: i));
      map[DateTime(date.year, date.month, date.day)] = 0.0;
    }

    for (final order in _orders) {
      final orderDate = DateTime(
        order.orderDate.year,
        order.orderDate.month,
        order.orderDate.day,
      );
      if (orderDate.isAfter(start.subtract(const Duration(days: 1))) &&
          orderDate.isBefore(now.add(const Duration(days: 1)))) {
        map[orderDate] = (map[orderDate] ?? 0) + order.totalAmount;
      }
    }

    return map;
  }

  Widget _buildProductPerformance() {
    final productSales = _calculateProductSales();
    final topProducts = productSales.entries.toList()
      ..sort((a, b) => b.value['revenue'].compareTo(a.value['revenue']));
    final top5 = topProducts.take(5).toList();

    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Performing Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (top5.isEmpty)
            const Center(
              child: Text(
                'No sales data available',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            Column(
              children: top5.map((entry) {
                final product = _products.firstWhere(
                  (p) => p.id == entry.key,
                  orElse: () => Product(
                    id: entry.key,
                    name: 'Unknown Product',
                    description: '',
                    price: 0.0,
                    unit: 'item',
                    taxRate: 0.0,
                    category: 'Unknown',
                    stockQuantity: 0,
                    isService: false,
                    isActive: true,
                    brand: 'Unknown',
                    ageRange: 'Unknown',
                    imageUrls: [],
                    isFeatured: false,
                    createdAt: DateTime.now(),
                  ),
                );
                final data = entry.value;
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
                        width: 50,
                        height: 50,
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
                            ? Icon(Icons.image, color: Colors.grey[500])
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${data['quantity']} sold • \$${data['revenue'].toStringAsFixed(2)} revenue',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#${top5.indexOf(entry) + 1}',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Map<String, Map<String, dynamic>> _calculateProductSales() {
    final productSales = <String, Map<String, dynamic>>{};

    for (final order in _orders) {
      for (final item in order.items) {
        final productId = item.productId;
        productSales[productId] ??= {'quantity': 0, 'revenue': 0.0};
        productSales[productId]!['quantity'] += item.quantity;
        productSales[productId]!['revenue'] += item.totalPrice;
      }
    }

    return productSales;
  }

  Widget _buildCustomerInsights() {
    final customerData = _calculateCustomerInsights();

    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  'New Customers',
                  customerData['newCustomers'].toString(),
                  'This month',
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInsightCard(
                  'Repeat Customers',
                  customerData['repeatCustomers'].toString(),
                  '${customerData['repeatRate'].toStringAsFixed(1)}% of total',
                  AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  'Avg Customer Value',
                  '\$${customerData['avgCustomerValue'].toStringAsFixed(2)}',
                  'Lifetime value',
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInsightCard(
                  'Customer Retention',
                  '${customerData['retentionRate'].toStringAsFixed(1)}%',
                  '30-day retention',
                  AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateCustomerInsights() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);

    final thisMonthOrders = _orders
        .where((o) => o.orderDate.isAfter(thisMonth))
        .toList();
    final lastMonthOrders = _orders
        .where(
          (o) =>
              o.orderDate.isAfter(lastMonth) && o.orderDate.isBefore(thisMonth),
        )
        .toList();

    final thisMonthCustomers = thisMonthOrders.map((o) => o.userId).toSet();
    final lastMonthCustomers = lastMonthOrders.map((o) => o.userId).toSet();

    final newCustomers = thisMonthCustomers
        .difference(lastMonthCustomers)
        .length;
    final repeatCustomers = thisMonthCustomers
        .intersection(lastMonthCustomers)
        .length;

    final totalCustomers = thisMonthCustomers.length;
    final repeatRate = totalCustomers > 0
        ? (repeatCustomers / totalCustomers) * 100
        : 0;

    final totalRevenue = _orders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );
    final uniqueCustomers = _orders.map((o) => o.userId).toSet().length;
    final avgCustomerValue = uniqueCustomers > 0
        ? totalRevenue / uniqueCustomers
        : 0;

    // Simple retention calculation (customers who ordered in both months)
    final retentionRate = lastMonthCustomers.isNotEmpty
        ? (repeatCustomers / lastMonthCustomers.length) * 100
        : 0;

    return {
      'newCustomers': newCustomers,
      'repeatCustomers': repeatCustomers,
      'repeatRate': repeatRate,
      'avgCustomerValue': avgCustomerValue,
      'retentionRate': retentionRate,
    };
  }

  Widget _buildInsightCard(
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: .7)),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryAnalytics() {
    final lowStock = _products.where((p) => p.stock <= 5).length;
    final outOfStock = _products.where((p) => p.stock == 0).length;
    final totalValue = _products.fold<double>(
      0,
      (sum, p) => sum + (p.price * p.stock),
    );

    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inventory Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInventoryMetric(
                  'Low Stock Items',
                  lowStock.toString(),
                  '≤5 units',
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInventoryMetric(
                  'Out of Stock',
                  outOfStock.toString(),
                  '0 units',
                  AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInventoryMetric(
                  'Total Value',
                  '\$${totalValue.toStringAsFixed(0)}',
                  'Inventory worth',
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryMetric(
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Column(
        children: [
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
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 8, color: color.withValues(alpha: .7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------
     2-e  Helpers
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

/* -------------  revenue chart painter  ------------- */
class _RevenueChartPainter extends CustomPainter {
  final Map<DateTime, double> data;

  const _RevenueChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxRevenue = entries.fold<double>(
      0,
      (max, e) => e.value > max ? e.value : max,
    );

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: .3),
          AppColors.primary.withValues(alpha: .1),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (entries.length - 1).clamp(1, double.infinity);

    for (int i = 0; i < entries.length; i++) {
      final x = stepX * i;
      final y = size.height - (entries[i].value / maxRevenue) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(stepX * (entries.length - 1), size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()..color = AppColors.primary;
    for (int i = 0; i < entries.length; i++) {
      final x = stepX * i;
      final y = size.height - (entries[i].value / maxRevenue) * size.height;
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
