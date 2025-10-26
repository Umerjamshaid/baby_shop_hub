import 'dart:ui';
import 'package:baby_shophub/models/order_model.dart';
import 'package:baby_shophub/models/product_model.dart';
import 'package:baby_shophub/models/user_model.dart';
import 'package:baby_shophub/providers/auth_provider.dart';
import 'package:baby_shophub/screens/admin/admin_edit_product_screen.dart';
import 'package:baby_shophub/screens/admin/admin_login_screen.dart';
import 'package:baby_shophub/screens/admin/admin_orders_screen.dart';
import 'package:baby_shophub/screens/admin/admin_products_screen.dart';
import 'package:baby_shophub/screens/admin/admin_users_screen.dart';
import 'package:baby_shophub/screens/admin/categories_screen.dart';
import 'package:baby_shophub/screens/admin/notification_management_screen.dart';
import 'package:baby_shophub/services/admin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  /* -------------------------------------------------
     2-a  Animation & scroll stuff
     ------------------------------------------------- */
  late AnimationController _animationController;
  late ScrollController _scrollCtrl;
  bool _isLoading = true;
  double _appBarOpacity = 0;

  final AdminService _adminService = AdminService();
  Map<String, dynamic> _stats = {};
  final int _salesDays = 7; // made final – prefer_final_fields

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
    _loadDashboardStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final stats = await _adminService.getDashboardStats();
      if (!mounted) return; // use_build_context_synchronously
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (!mounted) return; // use_build_context_synchronously
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load dashboard: $e'),
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
      drawer: _buildDrawer(context), // needs context
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
                ..._buildDashboardSlivers(),
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
        'Admin Dashboard',
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
            color: AppColors.success.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.file_download_rounded),
            color: AppColors.success,
            onPressed: _exportCsv,
          ),
        ),
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
              _loadDashboardStats();
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout_rounded),
            color: AppColors.error,
            onPressed: _logout,
          ),
        ),
      ],
    );
  }

  /* -------------------------------------------------
     2-d  Dashboard content
     ------------------------------------------------- */
  List<Widget> _buildDashboardSlivers() {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _WelcomeCard(stats: _stats),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _StatsGrid(stats: _stats),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _SalesOverTimeCard(stats: _stats, days: _salesDays),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _CategoryPieCard(stats: _stats),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _RecentActivityCard(stats: _stats),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _TopCustomersCard(stats: _stats),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _LowStockCard(stats: _stats),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _PopularProductsCard(stats: _stats),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _QuickActionsCard(),
        ),
      ),
    ];
  }

  /* -------------------------------------------------
     2-e  Helpers
     ------------------------------------------------- */
  List<Widget> _buildShimmerSliver() => [
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ShimmerWidget.rect(height: 180, radius: 24),
      ),
    ),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ShimmerWidget.rect(height: 120, radius: 24),
      ),
    ),
  ];

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (_) => false,
    );
  }

  Future<void> _exportCsv() async {
    try {
      final orders = await _adminService.getAllOrders();
      final buffer = StringBuffer();
      buffer.writeln('id,userId,totalAmount,status,orderDate');
      for (final o in orders) {
        buffer.writeln(
          '${o.id},${o.userId},${o.totalAmount.toStringAsFixed(2)},${o.status},${o.orderDate.toIso8601String()}',
        );
      }
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV copied to clipboard'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/* ==========================================================
   3.  RE-USABLE WIDGETS
   ========================================================== */

/* -------------  welcome card  ------------- */
class _WelcomeCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _WelcomeCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _NeuroCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back, Admin!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Here\'s what\'s happening with your store today.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: .8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.waving_hand, color: AppColors.primary, size: 32),
        ],
      ),
    );
  }
}

/* -------------  stats grid  ------------- */
class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final data = [
      {
        'title': 'Total Users',
        'value': (stats['totalUsers']?.toString() ?? '0'),
        'icon': Icons.people_outline,
        'gradient': const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      },
      {
        'title': 'Total Products',
        'value': (stats['totalProducts']?.toString() ?? '0'),
        'icon': Icons.inventory_2_outlined,
        'gradient': const LinearGradient(
          colors: [AppColors.success, Color(0xFF059669)],
        ),
      },
      {
        'title': 'Total Orders',
        'value': (stats['totalOrders']?.toString() ?? '0'),
        'icon': Icons.shopping_cart_outlined,
        'gradient': const LinearGradient(
          colors: [AppColors.secondary, Color(0xFFDB2777)],
        ),
      },
      {
        'title': 'Total Sales',
        'value': '\$${(stats['totalSales']?.toStringAsFixed(2) ?? '0.00')}',
        'icon': Icons.trending_up,
        'gradient': const LinearGradient(
          colors: [AppColors.warning, Color(0xFFF59E0B)],
        ),
      },
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final item = data[i];
        return _AnimatedStatCard(
          title: item['title'] as String,
          value: item['value'] as String,
          icon: item['icon'] as IconData,
          gradient: item['gradient'] as LinearGradient,
        );
      },
    );
  }
}

/* -------------  animated stat card  ------------- */
class _AnimatedStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  const _AnimatedStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _scale = Tween<double>(
      begin: .9,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Transform.scale(
          scale: _scale.value,
          child: FadeTransition(
            opacity: _fade,
            child: Container(
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.colors.first.withValues(alpha: .3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(widget.icon, size: 24, color: Colors.white),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '+12%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      widget.value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: .8),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/* -------------  sales over time card  ------------- */
class _SalesOverTimeCard extends StatefulWidget {
  final Map<String, dynamic> stats;
  final int days;
  const _SalesOverTimeCard({required this.stats, required this.days});

  @override
  State<_SalesOverTimeCard> createState() => _SalesOverTimeCardState();
}

class _SalesOverTimeCardState extends State<_SalesOverTimeCard> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = AdminService().getAllOrders();
  }

  Map<DateTime, double> _aggregateSalesByDay(List<Order> orders) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: widget.days - 1));
    final map = <DateTime, double>{};
    for (int i = 0; i < widget.days; i++) {
      final d = start.add(Duration(days: i));
      map[d] = 0.0;
    }
    for (final o in orders) {
      final d = DateTime(o.orderDate.year, o.orderDate.month, o.orderDate.day);
      if (d.isAfter(start.subtract(const Duration(days: 1))) &&
          d.isBefore(now.add(const Duration(days: 1)))) {
        map[d] = (map[d] ?? 0) + o.totalAmount;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales (Last ${widget.days} Days)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              ToggleButtons(
                isSelected: [widget.days == 7, widget.days == 30],
                onPressed: (_) {},
                borderRadius: BorderRadius.circular(12),
                constraints: const BoxConstraints(minHeight: 36, minWidth: 48),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('7D'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('30D'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Order>>(
            future: _ordersFuture,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final orders = snap.data!;
              final salesMap = _aggregateSalesByDay(orders);
              final entries = salesMap.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key));
              final maxY = entries.fold<double>(
                0,
                (m, e) => e.value > m ? e.value : m,
              );
              return Column(
                children: [
                  SizedBox(
                    height: 160,
                    child: CustomPaint(
                      painter: _LineChartPainter(entries: entries, maxY: maxY),
                      size: const Size(double.infinity, 160),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: entries.map((e) {
                      final d = e.key;
                      return Text(
                        '${d.month}/${d.day}',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary.withValues(alpha: .6),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/* -------------  category pie card  ------------- */
class _CategoryPieCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _CategoryPieCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final popular = stats['popularProducts'] as List<dynamic>? ?? [];
    final Map<String, double> categoryToCount = {};
    for (final item in popular) {
      final product = item['product'] as Product?;
      final count = (item['count'] as int? ?? 0).toDouble();
      if (product != null) {
        categoryToCount[product.category] =
            (categoryToCount[product.category] ?? 0) + count;
      }
    }
    final entries = categoryToCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return _NeuroCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Not enough data',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: .6),
            ),
          ),
        ),
      );
    }

    final total = entries.fold<double>(0, (sum, e) => sum + e.value);
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.secondary,
      AppColors.error,
    ];

    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _PieChartPainter(
                slices: List.generate(entries.length, (i) {
                  return _PieSlice(
                    value: entries[i].value,
                    color: colors[i % colors.length],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(entries.length, (i) {
              final e = entries[i];
              final percent = total > 0
                  ? (e.value / total * 100).toStringAsFixed(1)
                  : '0.0';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('${e.key} • $percent%'),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/* -------------  recent activity card  ------------- */
class _RecentActivityCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _RecentActivityCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final orders = (stats['recentOrders'] as List<Order>? ?? [])
        .take(5)
        .toList();
    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                ),
                icon: const Icon(Icons.list_alt),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            Center(
              child: Text(
                'No recent orders',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: .6),
                ),
              ),
            )
          else
            Column(
              children: orders.map((o) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: .1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${o.id.substring(0, 6)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${o.status} • \$${o.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(
                                  alpha: .8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

/* -------------  top customers card  ------------- */
class _TopCustomersCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _TopCustomersCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final orders = (stats['recentOrders'] as List<Order>? ?? []);
    final Map<String, double> userToSales = {};
    final Map<String, int> userToOrders = {};
    for (final o in orders) {
      userToSales[o.userId] = (userToSales[o.userId] ?? 0) + o.totalAmount;
      userToOrders[o.userId] = (userToOrders[o.userId] ?? 0) + 1;
    }
    final top = userToSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = top.take(5).toList();

    final usersRaw = (stats['usersRaw'] as List<dynamic>? ?? [])
        .whereType<UserModel>()
        .toList();

    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Customers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (top5.isEmpty)
            Center(
              child: Text(
                'No customers yet',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: .6),
                ),
              ),
            )
          else
            Column(
              children: top5.map((e) {
                final userId = e.key;
                final sales = e.value;
                final ordersCount = userToOrders[userId] ?? 0;
                final user = usersRaw.firstWhere(
                  (u) => u.id == userId,
                  orElse: () => UserModel(
                    id: userId,
                    email: 'unknown@user',
                    name: 'User $userId',
                    createdAt: DateTime.now(),
                  ),
                );
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: .1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: .2,
                        ),
                        backgroundImage:
                            (user.profileImage != null &&
                                user.profileImage!.isNotEmpty)
                            ? NetworkImage(user.profileImage!)
                            : null,
                        child:
                            (user.profileImage == null ||
                                user.profileImage!.isEmpty)
                            ? const Icon(Icons.person, color: AppColors.primary)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${user.email} • Orders: $ordersCount • Sales: \$${sales.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(
                                  alpha: .8,
                                ),
                              ),
                            ),
                          ],
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
}

/* -------------  low stock card  ------------- */
class _LowStockCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _LowStockCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final products = (stats['popularProducts'] as List<dynamic>? ?? [])
        .map((e) => e['product'] as Product?)
        .whereType<Product>()
        .toList();
    final lowStock = products.where((p) => p.stock <= 5).take(5).toList();

    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Low Stock Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (lowStock.isEmpty)
            Center(
              child: Text(
                'All good! No low-stock items',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: .6),
                ),
              ),
            )
          else
            Column(
              children: lowStock.map((p) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: .1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: NetworkImage(
                              p.imageUrls?.isNotEmpty == true
                                  ? p.imageUrls!.first
                                  : 'https://via.placeholder.com/44',
                            ),
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
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Stock: ${p.stock}',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AdminEditProductScreen(onProductSaved: () {}),
                          ),
                        ),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Update'),
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
}

/* -------------  popular products card  ------------- */
class _PopularProductsCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _PopularProductsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final popular = (stats['popularProducts'] as List<dynamic>? ?? [])
        .take(5)
        .toList();

    return _NeuroCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EnhancedProductManagementScreen(),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (popular.isEmpty)
            Center(
              child: Text(
                'No popular products yet',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: .6),
                ),
              ),
            )
          else
            Column(
              children: popular.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final product = item['product'] as Product?;
                final count = item['count'] as int? ?? 0;
                final revenue = item['revenue'] as double? ?? 0.0;

                if (product == null) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: index < popular.length - 1
                        ? Border(
                            bottom: BorderSide(
                              color: Colors.grey.withValues(alpha: .1),
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(
                            image: NetworkImage(
                              product.imageUrls?.isNotEmpty == true
                                  ? product.imageUrls![0]
                                  : 'https://via.placeholder.com/60',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sold: $count • Revenue: \$${revenue.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(
                                  alpha: .8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.trending_up,
                          color: AppColors.primary,
                          size: 20,
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
}

/* -------------  quick actions card  ------------- */
class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'title': 'Add Product',
        'subtitle': 'Add new items to inventory',
        'icon': Icons.add_box,
        'color': AppColors.success,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminEditProductScreen(onProductSaved: () {}),
          ),
        ),
      },
      {
        'title': 'Manage Categories',
        'subtitle': 'Organize product categories',
        'icon': Icons.category,
        'color': AppColors.warning,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CategoriesScreen()),
        ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...actions.map(
          (action) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                (action['onTap'] as VoidCallback)();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            action['subtitle'] as String,
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(
                                alpha: .8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/* ==========================================================
   4.  SMALL UI COMPONENTS
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

/* -------------  drawer  ------------- */
Drawer _buildDrawer(BuildContext context) {
  final menuItems = [
    {'icon': Icons.dashboard, 'title': 'Dashboard', 'color': AppColors.primary},
    {'icon': Icons.inventory, 'title': 'Products', 'color': AppColors.success},
    {'icon': Icons.add_box, 'title': 'Add Product', 'color': AppColors.success},
    {'icon': Icons.category, 'title': 'Categories', 'color': AppColors.warning},
    {
      'icon': Icons.shopping_cart,
      'title': 'Orders',
      'color': AppColors.secondary,
    },
    {'icon': Icons.people, 'title': 'Users', 'color': AppColors.primary},
    {
      'icon': Icons.notifications,
      'title': 'Notifications',
      'color': AppColors.warning,
    },
  ];

  return Drawer(
    child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF818CF8)],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dashboard Control Center',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ...menuItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                title: Text(
                  item['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => _handleMenuTap(context, index),
              ),
            );
          }),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: const Divider(color: Colors.white54),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.exit_to_app,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                final auth = context.read<AuthProvider>();
                auth.signOut().then((_) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                    (_) => false,
                  );
                });
              },
            ),
          ),
        ],
      ),
    ),
  );
}

void _handleMenuTap(BuildContext context, int index) {
  Navigator.pop(context);
  switch (index) {
    case 0:
      break; // dashboard
    case 1:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const EnhancedProductManagementScreen(),
        ),
      );
      break;
    case 2:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminEditProductScreen(onProductSaved: () {}),
        ),
      );
      break;
    case 3:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CategoriesScreen()),
      );
      break;
    case 4:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
      );
      break;
    case 5:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
      );
      break;
    case 6:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationManagementScreen()),
      );
      break;
  }
}

/* -------------  line chart painter  ------------- */
class _LineChartPainter extends CustomPainter {
  final List<MapEntry<DateTime, double>> entries;
  final double maxY;

  const _LineChartPainter({required this.entries, required this.maxY});

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 12.0;
    final width = size.width - padding * 2;
    final height = size.height - padding * 2;

    final bgPaint = Paint()
      ..color = const Color(0xFFF7F7F7)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
      bgPaint,
    );

    final gridPaint = Paint()
      ..color = const Color(0xFFEAEAEA)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = padding + height * (i / 4);
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    if (entries.isEmpty || maxY <= 0) return;

    final path = Path();
    final dotPaint = Paint()..color = AppColors.primary;
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: .5),
          AppColors.primary.withValues(alpha: .1),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    final stepX = width / (entries.length - 1).clamp(1, double.infinity);

    for (int i = 0; i < entries.length; i++) {
      final x = padding + stepX * i;
      final value = entries[i].value;
      final y = padding + height - (value / maxY) * height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(padding + stepX * (entries.length - 1), padding + height)
      ..lineTo(padding, padding + height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < entries.length; i++) {
      final x = padding + stepX * i;
      final value = entries[i].value;
      final y = padding + height - (value / maxY) * height;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/* -------------  pie slice  ------------- */
class _PieSlice {
  final double value;
  final Color color;
  const _PieSlice({required this.value, required this.color});
}

/* -------------  pie chart painter  ------------- */
class _PieChartPainter extends CustomPainter {
  final List<_PieSlice> slices;
  const _PieChartPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = rect.center;
    final radius = (size.shortestSide * 0.35);

    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    double startAngle = -3.14 / 2;
    for (final s in slices) {
      final sweep = (s.value / total) * 3.14 * 2;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = s.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
