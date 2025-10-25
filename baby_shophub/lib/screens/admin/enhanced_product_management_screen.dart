import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product_model.dart';
import '../../services/admin_service.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import 'admin_edit_product_screen.dart';

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
class EnhancedProductManagementScreen extends StatefulWidget {
  const EnhancedProductManagementScreen({super.key});

  @override
  State<EnhancedProductManagementScreen> createState() =>
      _EnhancedProductManagementScreenState();
}

class _EnhancedProductManagementScreenState
    extends State<EnhancedProductManagementScreen>
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
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _sortBy = 'name';
  bool _sortAscending = true;

  final TextEditingController _searchController = TextEditingController();

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
    _searchController.addListener(_onSearchChanged);
    _loadProducts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterAndSortProducts();
    });
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getAllProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _filterAndSortProducts();
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load products: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _filterAndSortProducts() {
    List<Product> filtered = _products.where((product) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesCategory =
          _selectedCategory == 'All' || product.category == _selectedCategory;

      final matchesStatus =
          _selectedStatus == 'All' ||
          (_selectedStatus == 'In Stock' && product.inStock) ||
          (_selectedStatus == 'Out of Stock' && !product.inStock) ||
          (_selectedStatus == 'Featured' && product.isFeatured);

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      int compare;
      switch (_sortBy) {
        case 'name':
          compare = a.name.compareTo(b.name);
          break;
        case 'price':
          compare = a.price.compareTo(b.price);
          break;
        case 'stock':
          compare = a.stock.compareTo(b.stock);
          break;
        case 'category':
          compare = a.category.compareTo(b.category);
          break;
        default:
          compare = 0;
      }
      return _sortAscending ? compare : -compare;
    });

    setState(() => _filteredProducts = filtered);
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
                ..._buildProductManagementSlivers(),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
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
        'Enhanced Product Management',
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
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.primary,
            onPressed: () {
              _animationController.reset();
              _loadProducts();
            },
          ),
        ),
      ],
    );
  }

  /* -------------------------------------------------
     2-d  Product management content
     ------------------------------------------------- */
  List<Widget> _buildProductManagementSlivers() {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _buildFiltersAndStats(),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: _buildProductList(),
        ),
      ),
    ];
  }

  Widget _buildFiltersAndStats() {
    final categories = ['All', ..._products.map((p) => p.category).toSet()];
    final statuses = ['All', 'In Stock', 'Out of Stock', 'Featured'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Container(
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
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Filters Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Category Filter
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                        _filterAndSortProducts();
                      });
                    },
                    style: const TextStyle(color: AppColors.textPrimary),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              // Status Filter
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    items: statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                        _filterAndSortProducts();
                      });
                    },
                    style: const TextStyle(color: AppColors.textPrimary),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              // Sort By
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    items: const [
                      DropdownMenuItem(value: 'name', child: Text('Name')),
                      DropdownMenuItem(value: 'price', child: Text('Price')),
                      DropdownMenuItem(value: 'stock', child: Text('Stock')),
                      DropdownMenuItem(
                        value: 'category',
                        child: Text('Category'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                        _filterAndSortProducts();
                      });
                    },
                    style: const TextStyle(color: AppColors.textPrimary),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              // Sort Direction
              IconButton(
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                    _filterAndSortProducts();
                  });
                },
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Stats Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Products',
                _products.length.toString(),
                Icons.inventory,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'In Stock',
                _products.where((p) => p.inStock).length.toString(),
                Icons.check_circle,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Low Stock',
                _products.where((p) => p.stock <= 5).length.toString(),
                Icons.warning,
                AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
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
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildEnhancedProductCard(product),
        );
      },
    );
  }

  Widget _buildEnhancedProductCard(Product product) {
    return Container(
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editProduct(product),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: product.firstImage.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(product.firstImage),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: product.firstImage.isEmpty ? Colors.grey[200] : null,
                ),
                child: product.firstImage.isEmpty
                    ? Icon(Icons.image, color: Colors.grey[500])
                    : null,
              ),
              const SizedBox(width: 16),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.isFeatured)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Featured',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.category} • ${product.formattedPrice}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          product.inStock ? Icons.check_circle : Icons.cancel,
                          size: 14,
                          color: product.inStock
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.inStock
                              ? 'In Stock (${product.stock})'
                              : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 12,
                            color: product.inStock
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Column(
                children: [
                  IconButton(
                    onPressed: () => _editProduct(product),
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    tooltip: 'Edit Product',
                  ),
                  IconButton(
                    onPressed: () => _deleteProduct(product),
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    tooltip: 'Delete Product',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: .5),
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or add a new product',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: .7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _addNewProduct,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Add Product'),
      elevation: 6,
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
        child: ShimmerWidget.rect(height: 120, radius: 16),
      ),
    ),
  ];

  void _addNewProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEditProductScreen(onProductSaved: _loadProducts),
      ),
    );
  }

  void _editProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEditProductScreen(
          product: product,
          onProductSaved: _loadProducts,
        ),
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning, color: Colors.red[700], size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Delete Product'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this product? This action cannot be undone.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteProduct(product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Product deleted successfully'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _loadProducts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Failed to delete product: $e')),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

/* ==========================================================
   3.  SMALL UI COMPONENTS
   ========================================================== */

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
