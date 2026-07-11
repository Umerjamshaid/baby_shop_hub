import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/product_model.dart';
import '../models/search_filters_model.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/common/product_card.dart';
import './product_detail_screen.dart';
import './advanced_search_screen.dart';
import './cart_screen.dart';

class ProductsListScreen extends StatefulWidget {
  final String? category;
  final String? searchQuery;
  final SearchFilters? searchFilters;

  const ProductsListScreen({
    super.key,
    this.category,
    this.searchQuery,
    this.searchFilters,
  });

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  String _currentSort = 'name';
  bool _isGridView = true;
  bool _showScrollToTop = false;
  late SearchFilters _filters;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _filters =
        widget.searchFilters ??
        SearchFilters(
          category: widget.category ?? 'All',
          query: widget.searchQuery ?? '',
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
      _animationController.forward();
    });

    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 300;
      if (shouldShow != _showScrollToTop) {
        setState(() {
          _showScrollToTop = shouldShow;
        });
      }
    });
  }

  @override
  void didUpdateWidget(ProductsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload products if category or search query changes
    if (oldWidget.category != widget.category ||
        oldWidget.searchQuery != widget.searchQuery) {
      _loadProducts();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    // If we're coming from a category or search, apply the filter
    if (widget.category != null && widget.category != 'All') {
      productProvider.filterProductsByCategory(widget.category!);
    } else if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      productProvider.searchProducts(widget.searchQuery!);
    } else {
      // If no category or search query, or category is "All", show all products
      productProvider.loadAllProducts();
    }
  }

  void _sortProducts(String sortBy) {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    productProvider.sortProducts(sortBy);

    setState(() {
      _currentSort = sortBy;
    });
  }

  String _getScreenTitle() {
    if (_filters.query.isNotEmpty) {
      return 'Search: ${_filters.query}';
    } else if (_filters.category != 'All') {
      return _filters.category;
    } else if (_filters.hasFilters) {
      return 'Filtered Products';
    } else {
      return widget.category ?? widget.searchQuery ?? 'All Products';
    }
  }

  void _triggerNewSearch(String suggestion) {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    setState(() {
      _filters = SearchFilters(category: 'All', query: suggestion);
    });

    productProvider.loadProductsWithFilters(_filters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 80,
            leading: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black87,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getScreenTitle(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Consumer<ProductProvider>(
                  builder: (context, provider, _) {
                    final count = provider.filteredProducts.length;
                    return Text(
                      '$count ${count == 1 ? 'product' : 'products'} found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              _buildActionButton(
                icon: Icons.filter_list_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdvancedSearchScreen(
                        initialCategory: _filters.category,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: _isGridView
                    ? Icons.list_rounded
                    : Icons.grid_view_rounded,
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildSortButton(),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<ProductProvider>(
          builder: (context, productProvider, _) {
            if (productProvider.isLoading) {
              return const AppLoadingWidget();
            }

            if (productProvider.error != null) {
              return AppErrorWidget(
                message: productProvider.error!,
                onRetry: _loadProducts,
              );
            }

            final products = productProvider.filteredProducts;

            if (products.isEmpty) {
              return _buildNoResultsState(widget.searchQuery ?? _filters.query);
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadProducts();
              },
              color: const Color(0xFF6B73FF),
              backgroundColor: Colors.white,
              child: _isGridView
                  ? _buildEnhancedGridView(products)
                  : _buildEnhancedListView(products),
            );
          },
        ),
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: _showScrollToTop ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _showScrollToTop ? 1.0 : 0.0,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            scale: _showScrollToTop ? 1.0 : 0.9,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton(
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                  );
                },
                backgroundColor: Theme.of(context).primaryColor,
                tooltip: 'Scroll to top',
                mini: true,
                heroTag: 'products_list_scroll_top',
                child: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSortButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        onSelected: _sortProducts,
        icon: const Icon(Icons.sort_rounded, color: Colors.black87, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        itemBuilder: (BuildContext context) {
          return [
            _buildSortOption(
              'name',
              Icons.sort_by_alpha_rounded,
              'Sort by Name',
            ),
            _buildSortOption(
              'price_low',
              Icons.trending_up_rounded,
              'Price: Low to High',
            ),
            _buildSortOption(
              'price_high',
              Icons.trending_down_rounded,
              'Price: High to Low',
            ),
            _buildSortOption('rating', Icons.star_rounded, 'Sort by Rating'),
          ];
        },
      ),
    );
  }

  PopupMenuItem<String> _buildSortOption(
    String value,
    IconData icon,
    String text,
  ) {
    final isSelected = _currentSort == value;
    return PopupMenuItem(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(String query) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              query.isEmpty
                  ? 'No products available'
                  : 'No results found for "$query"',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              query.isEmpty
                  ? 'Try browsing different categories'
                  : 'Try searching with different keywords',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Try these instead:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: ['Diapers', 'Toys', 'Clothing', 'Food'].map((
                      suggestion,
                    ) {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _triggerNewSearch(suggestion),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              suggestion,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdvancedSearchScreen(
                            initialCategory: _filters.category,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text(
                      'Adjust Filters',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadProducts,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: Icon(Icons.refresh_rounded, color: Colors.grey.shade600),
              label: Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedGridView(List<Product> products) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutBack,
            child: ProductCard(product: products[index]),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedListView(List<Product> products) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutBack,
          child: ProductListCard(product: products[index]),
        );
      },
    );
  }
}

class EnhancedProductCard extends StatefulWidget {
  final Product product;

  const EnhancedProductCard({super.key, required this.product});

  @override
  State<EnhancedProductCard> createState() => _EnhancedProductCardState();
}

class _EnhancedProductCardState extends State<EnhancedProductCard>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  bool _isHovered = false;
  late AnimationController _favoriteController;

  @override
  void initState() {
    super.initState();
    _favoriteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _favoriteController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUser != null) {
      _isFavorite = await favoritesProvider.isProductInFavorites(
        authProvider.currentUser!.id,
        widget.product.id,
      );
    }

    if (mounted) {
      setState(() {
        _isCheckingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.mediumImpact();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUser == null) {
      _showSnackBar('Please login to add favorites', Icons.login, Colors.blue);
      return;
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_isFavorite) {
      _favoriteController.forward();
    } else {
      _favoriteController.reverse();
    }

    try {
      if (_isFavorite) {
        await favoritesProvider.addToFavorites(
          authProvider.currentUser!.id,
          widget.product.id,
        );
        _showSnackBar('Added to favorites', Icons.favorite, Colors.red);
      } else {
        await favoritesProvider.removeFromFavorites(
          authProvider.currentUser!.id,
          widget.product.id,
        );
        _showSnackBar(
          'Removed from favorites',
          Icons.heart_broken,
          Colors.grey,
        );
      }
    } catch (e) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
      _showSnackBar('Failed to update favorites', Icons.error, Colors.red);
    }
  }

  void _shareProduct() {
    HapticFeedback.lightImpact();
    Share.share(
      'Check out this product: ${widget.product.name} - ${widget.product.formattedPrice}',
      subject: 'BabyShopHub Product',
    );
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(.4), width: 1),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: _toggleFavorite,
      child: AnimatedBuilder(
        animation: _favoriteController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_favoriteController.value * 0.3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _isFavorite
                        ? Colors.red.withOpacity(.9)
                        : Colors.white.withOpacity(.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isFavorite
                          ? Colors.red.withOpacity(.6)
                          : Colors.white.withOpacity(.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: _isFavorite ? Colors.white : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final authProvider = Provider.of<AuthProvider>(context);
        final isInCart = cartProvider.isInCart(widget.product.id);
        final isOutOfStock = !widget.product.inStock;

        return SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: isOutOfStock
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    if (authProvider.currentUser == null) {
                      _showSnackBar(
                        'Please login to add to cart',
                        Icons.login,
                        Colors.blue,
                      );
                      return;
                    }

                    if (isInCart) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    } else {
                      cartProvider.addToCart(
                        authProvider.currentUser!.id,
                        widget.product,
                      );
                      _showSnackBar(
                        'Added to cart',
                        Icons.shopping_cart,
                        Colors.green,
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isOutOfStock
                  ? Colors.grey.shade300
                  : isInCart
                  ? Colors.white
                  : Theme.of(context).primaryColor,
              foregroundColor: isInCart
                  ? Theme.of(context).primaryColor
                  : Colors.white,
              elevation: isInCart ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: isInCart
                    ? BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 1.5,
                      )
                    : BorderSide.none,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOutOfStock
                      ? Icons.block
                      : isInCart
                      ? Icons.shopping_cart
                      : Icons.add_shopping_cart_rounded,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  isOutOfStock
                      ? 'Out'
                      : isInCart
                      ? 'View'
                      : 'Add',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      transform: _isHovered
          ? Matrix4.translationValues(0, -4, 0)
          : Matrix4.identity(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProductDetailScreen(product: widget.product),
              ),
            );
          },
          onHover: (hovered) {
            setState(() {
              _isHovered = hovered;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.08),
                  blurRadius: _isHovered ? 24 : 20,
                  offset: Offset(0, _isHovered ? 10 : 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade200,
                                Colors.grey.shade100,
                              ],
                            ),
                          ),
                          child: Image.network(
                            widget.product.firstImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(.15),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.3, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Top action buttons
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 8,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildGlassButton(
                              icon: Icons.share_rounded,
                              onTap: _shareProduct,
                            ),
                            if (!_isCheckingFavorite) _buildFavoriteButton(),
                          ],
                        ),
                      ),
                      if (!widget.product.inStock)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade600,
                                  Colors.red.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Out of Stock',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                (widget.product.rating ?? 0).toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: Colors.black87,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.product.formattedPrice,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildAddToCartButton(),
                          ],
                        ),
                        if (widget.product.inStock) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade50,
                                  Colors.green.shade100,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              'In Stock',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// List view variant of product card - enhanced version
class ProductListCard extends StatefulWidget {
  final Product product;

  const ProductListCard({super.key, required this.product});

  @override
  State<ProductListCard> createState() => _ProductListCardState();
}

class _ProductListCardState extends State<ProductListCard>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  bool _isHovered = false;
  late AnimationController _favoriteController;

  @override
  void initState() {
    super.initState();
    _favoriteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _favoriteController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUser != null) {
      _isFavorite = await favoritesProvider.isProductInFavorites(
        authProvider.currentUser!.id,
        widget.product.id,
      );
    }

    if (mounted) {
      setState(() {
        _isCheckingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.mediumImpact();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUser == null) {
      _showSnackBar('Please login to add favorites', Icons.login, Colors.blue);
      return;
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_isFavorite) {
      _favoriteController.forward();
    } else {
      _favoriteController.reverse();
    }

    try {
      if (_isFavorite) {
        await favoritesProvider.addToFavorites(
          authProvider.currentUser!.id,
          widget.product.id,
        );
        _showSnackBar('Added to favorites', Icons.favorite, Colors.red);
      } else {
        await favoritesProvider.removeFromFavorites(
          authProvider.currentUser!.id,
          widget.product.id,
        );
        _showSnackBar(
          'Removed from favorites',
          Icons.heart_broken,
          Colors.grey,
        );
      }
    } catch (e) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
      _showSnackBar('Failed to update favorites', Icons.error, Colors.red);
    }
  }

  void _shareProduct() {
    HapticFeedback.lightImpact();
    Share.share(
      'Check out this product: ${widget.product.name} - ${widget.product.formattedPrice}',
      subject: 'BabyShopHub Product',
    );
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(.4), width: 1),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: _toggleFavorite,
      child: AnimatedBuilder(
        animation: _favoriteController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_favoriteController.value * 0.3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _isFavorite
                        ? Colors.red.withOpacity(.9)
                        : Colors.white.withOpacity(.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isFavorite
                          ? Colors.red.withOpacity(.6)
                          : Colors.white.withOpacity(.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border_rounded,
                    size: 16,
                    color: _isFavorite ? Colors.white : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final authProvider = Provider.of<AuthProvider>(context);
        final isInCart = cartProvider.isInCart(widget.product.id);
        final isOutOfStock = !widget.product.inStock;

        return SizedBox(
          height: 32,
          width: 70,
          child: ElevatedButton(
            onPressed: isOutOfStock
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    if (authProvider.currentUser == null) {
                      _showSnackBar(
                        'Please login to add to cart',
                        Icons.login,
                        Colors.blue,
                      );
                      return;
                    }

                    if (isInCart) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    } else {
                      cartProvider.addToCart(
                        authProvider.currentUser!.id,
                        widget.product,
                      );
                      _showSnackBar(
                        'Added to cart',
                        Icons.shopping_cart,
                        Colors.green,
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isOutOfStock
                  ? Colors.grey.shade300
                  : isInCart
                  ? Colors.white
                  : Theme.of(context).primaryColor,
              foregroundColor: isInCart
                  ? Theme.of(context).primaryColor
                  : Colors.white,
              elevation: isInCart ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: isInCart
                    ? BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 1.5,
                      )
                    : BorderSide.none,
              ),
              padding: EdgeInsets.zero,
            ),
            child: Icon(
              isOutOfStock
                  ? Icons.block
                  : isInCart
                  ? Icons.shopping_cart
                  : Icons.add,
              size: 16,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      transform: _isHovered
          ? Matrix4.translationValues(0, -2, 0)
          : Matrix4.identity(),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.08),
            blurRadius: _isHovered ? 24 : 20,
            offset: Offset(0, _isHovered ? 10 : 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProductDetailScreen(product: widget.product),
              ),
            );
          },
          onHover: (hovered) {
            setState(() {
              _isHovered = hovered;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Image with overlay buttons
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade200, Colors.grey.shade100],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: widget.product.firstImage.isNotEmpty
                            ? Image.network(
                                widget.product.firstImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image_not_supported_rounded,
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  );
                                },
                              )
                            : Icon(
                                Icons.image_not_supported_rounded,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                      ),
                    ),
                    // Top action buttons
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGlassButton(
                            icon: Icons.share_rounded,
                            onTap: _shareProduct,
                          ),
                          const SizedBox(width: 4),
                          if (!_isCheckingFavorite) _buildFavoriteButton(),
                        ],
                      ),
                    ),
                    // Out of stock overlay
                    if (!widget.product.inStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.black.withOpacity(0.5),
                          ),
                          child: const Center(
                            child: Text(
                              'Out of Stock',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.product.category,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.formattedPrice,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.amber.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 12,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        (widget.product.rating ?? 0)
                                            .toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildAddToCartButton(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
