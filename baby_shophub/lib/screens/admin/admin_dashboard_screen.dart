import 'package:baby_shophub/screens/admin/notification_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import 'admin_login_screen.dart';
import 'admin_products_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_users_screen.dart';
import 'categories_screen.dart';
import 'admin_edit_product_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _loadDashboardStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final stats = await _adminService.getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load dashboard: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _isLoading
          ? _buildLoadingWidget()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildDashboard(),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.dashboard, color: Color(0xFF6C5CE7)),
          const SizedBox(width: 8),
          Flexible(
            child: const Text(
              'Admin Dashboard',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6C5CE7)),
            onPressed: () {
              _animationController.reset();
              _loadDashboardStats();
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Loading Dashboard...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final menuItems = [
      {
        'icon': Icons.dashboard,
        'title': 'Dashboard',
        'color': const Color(0xFF6C5CE7),
      },
      {
        'icon': Icons.inventory,
        'title': 'Products',
        'color': const Color(0xFF00B894),
      },
      {
        'icon': Icons.add_box,
        'title': 'Add Product',
        'color': const Color(0xFF00B894),
      },
      {
        'icon': Icons.category,
        'title': 'Categories',
        'color': const Color(0xFFE17055),
      },
      {
        'icon': Icons.shopping_cart,
        'title': 'Orders',
        'color': const Color(0xFFFD79A8),
      },
      {
        'icon': Icons.people,
        'title': 'Users',
        'color': const Color(0xFF74B9FF),
      },
      {
        'icon': Icons.notifications,
        'title': 'Notifications',
        'color': const Color(0xFFFDCB6E),
      },
    ];

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
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
                      color: Colors.white.withOpacity(0.2),
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
                      color: Colors.white.withOpacity(0.8),
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
                      color: Colors.white.withOpacity(0.2),
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
                  onTap: () => _handleMenuTap(index),
                ),
              );
            }).toList(),
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
                    color: Colors.red.withOpacity(0.2),
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
                onTap: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuTap(int index) {
    Navigator.pop(context);
    switch (index) {
      case 0: // Dashboard - already here
        break;
      case 1: // Products
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminProductsScreen()),
        );
        break;
      case 2: // Add Product
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminEditProductScreen(onProductSaved: () {}),
          ),
        );
        break;
      case 3: // Categories
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CategoriesScreen()),
        );
        break;
      case 4: // Orders
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminOrdersScreen()),
        );
        break;
      case 5: // Users
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminUsersScreen()),
        );
        break;
      case 6: // Notifications
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationManagementScreen(),
          ),
        );
        break;
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 30),
          _buildStatsSection(),
          const SizedBox(height: 30),
          _buildPopularProductsSection(),
          const SizedBox(height: 30),
          _buildQuickActionsSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back, Admin!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Here\'s what\'s happening with your store today.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.waving_hand, color: Colors.white, size: 32),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Statistics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildStatsGrid(),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {
        'title': 'Total Users',
        'value': (_stats['totalUsers']?.toString() ?? '0'),
        'icon': Icons.people_outline,
        'gradient': const LinearGradient(
          colors: [Color(0xFF74B9FF), Color(0xFF0984E3)],
        ),
        'change': '+12%',
      },
      {
        'title': 'Total Products',
        'value': (_stats['totalProducts']?.toString() ?? '0'),
        'icon': Icons.inventory_2_outlined,
        'gradient': const LinearGradient(
          colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
        ),
        'change': '+8%',
      },
      {
        'title': 'Total Orders',
        'value': (_stats['totalOrders']?.toString() ?? '0'),
        'icon': Icons.shopping_cart_outlined,
        'gradient': const LinearGradient(
          colors: [Color(0xFFFD79A8), Color(0xFFE84393)],
        ),
        'change': '+23%',
      },
      {
        'title': 'Total Sales',
        'value': '\$${(_stats['totalSales']?.toStringAsFixed(2) ?? '0.00')}',
        'icon': Icons.trending_up,
        'gradient': const LinearGradient(
          colors: [Color(0xFFFDCB6E), Color(0xFFE17055)],
        ),
        'change': '+15%',
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
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          decoration: BoxDecoration(
            gradient: stat['gradient'] as LinearGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (stat['gradient'] as LinearGradient).colors.first
                    .withOpacity(0.3),
                blurRadius: 15,
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
                    Icon(
                      stat['icon'] as IconData,
                      size: 24,
                      color: Colors.white,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        stat['change'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    stat['value'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    stat['title'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopularProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Popular Products',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminProductsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPopularProducts(),
      ],
    );
  }

  Widget _buildPopularProducts() {
    final popularProducts = _stats['popularProducts'] as List<dynamic>? ?? [];

    if (popularProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.trending_up, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No popular products yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: popularProducts.asMap().entries.map<Widget>((entry) {
          final index = entry.key;
          final item = entry.value;
          final product = item['product'] as Product?;
          final count = item['count'] as int? ?? 0;
          final revenue = item['revenue'] as double? ?? 0.0;

          if (product == null) {
            return const SizedBox();
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: index < popularProducts.length - 1
                  ? Border(
                      bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
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
                        product.imageUrls.isNotEmpty
                            ? product.imageUrls[0]
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sold: $count • Revenue: \$${revenue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Color(0xFF6C5CE7),
                    size: 20,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final actions = [
      {
        'title': 'Add Product',
        'subtitle': 'Add new items to inventory',
        'icon': Icons.add_box,
        'color': const Color(0xFF00B894),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminEditProductScreen(onProductSaved: () {}),
          ),
        ),
      },
      {
        'title': 'Manage Categories',
        'subtitle': 'Organize product categories',
        'icon': Icons.category,
        'color': const Color(0xFFE17055),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CategoriesScreen()),
        ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...actions
            .map(
              (action) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: action['onTap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
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
                            color: (action['color'] as Color).withOpacity(0.1),
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
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                action['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      (route) => false,
    );
  }
}
