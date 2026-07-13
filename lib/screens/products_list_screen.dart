import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../models/search_filters_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/common/loading_widget.dart';
import './advanced_search_screen.dart';
import './cart_screen.dart';
import './product_detail_screen.dart';

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

class _ProductsListScreenState extends State<ProductsListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = true;
  String _currentSort = 'name';
  late SearchFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters =
        widget.searchFilters ??
        SearchFilters(
          category: widget.category ?? 'All',
          query: widget.searchQuery ?? '',
        );

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  @override
  void didUpdateWidget(covariant ProductsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category ||
        oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.searchFilters != widget.searchFilters) {
      _filters =
          widget.searchFilters ??
          SearchFilters(
            category: widget.category ?? 'All',
            query: widget.searchQuery ?? '',
          );
      _loadProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    if (widget.searchFilters != null) {
      productProvider.loadProductsWithFilters(_filters);
    } else if (widget.category != null && widget.category != 'All') {
      productProvider.filterProductsByCategory(widget.category!);
    } else if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      productProvider.searchProducts(widget.searchQuery!);
    } else {
      productProvider.loadAllProducts();
    }
  }

  void _sortProducts(String sortBy) {
    Provider.of<ProductProvider>(context, listen: false).sortProducts(sortBy);
    setState(() => _currentSort = sortBy);
  }

  String get _title {
    if (_filters.query.isNotEmpty) return 'Search results';
    if (_filters.category != 'All') return _filters.category;
    if (_filters.hasFilters) return 'Filtered products';
    return widget.category ?? 'All products';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            _ProductsHeader(
              title: _title,
              subtitle: _filters.query.isNotEmpty
                  ? '"${_filters.query}"'
                  : null,
              isGridView: _isGridView,
              onBack: () => Navigator.maybePop(context),
              onFilter: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdvancedSearchScreen(
                      initialCategory: _filters.category,
                    ),
                  ),
                );
              },
              onToggleView: () {
                setState(() => _isGridView = !_isGridView);
              },
              onSort: _sortProducts,
              currentSort: _currentSort,
            ),
            Expanded(
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
                    return _EmptyProductsState(onRetry: _loadProducts);
                  }

                  return RefreshIndicator(
                    color: const Color(0xff00A884),
                    onRefresh: () async => _loadProducts(),
                    child: _isGridView
                        ? _ProductsGrid(
                            controller: _scrollController,
                            products: products,
                          )
                        : _ProductsList(
                            controller: _scrollController,
                            products: products,
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isGridView;
  final VoidCallback onBack;
  final VoidCallback onFilter;
  final VoidCallback onToggleView;
  final ValueChanged<String> onSort;
  final String currentSort;

  const _ProductsHeader({
    required this.title,
    required this.subtitle,
    required this.isGridView,
    required this.onBack,
    required this.onFilter,
    required this.onToggleView,
    required this.onSort,
    required this.currentSort,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        children: [
          Row(
            children: [
              _HeaderIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: Color(0xff202020),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Consumer<ProductProvider>(
                      builder: (context, provider, _) {
                        final count = provider.filteredProducts.length;
                        return Text(
                          subtitle ?? '$count products available',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff8A8A8A),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              _HeaderIconButton(icon: Icons.tune_rounded, onTap: onFilter),
              const SizedBox(width: 10),
              _HeaderIconButton(
                icon: isGridView
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
                onTap: onToggleView,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SortChip(
                label: 'Name',
                value: 'name',
                currentSort: currentSort,
                onSort: onSort,
              ),
              const SizedBox(width: 10),
              _SortChip(
                label: 'Low price',
                value: 'price_low',
                currentSort: currentSort,
                onSort: onSort,
              ),
              const SizedBox(width: 10),
              _SortChip(
                label: 'High price',
                value: 'price_high',
                currentSort: currentSort,
                onSort: onSort,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, size: 21, color: const Color(0xff202020)),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final String currentSort;
  final ValueChanged<String> onSort;

  const _SortChip({
    required this.label,
    required this.value,
    required this.currentSort,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final selected = currentSort == value;

    return InkWell(
      onTap: () => onSort(value),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff202020) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.08 : 0.035),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : const Color(0xff777777),
          ),
        ),
      ),
    );
  }
}

class _ProductsGrid extends StatelessWidget {
  final List<Product> products;
  final ScrollController controller;

  const _ProductsGrid({required this.products, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        44 + MediaQuery.of(context).padding.bottom,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58,
        crossAxisSpacing: 16,
        mainAxisSpacing: 18,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) =>
          _ShopProductCard(product: products[index]),
    );
  }
}

class _ProductsList extends StatelessWidget {
  final List<Product> products;
  final ScrollController controller;

  const _ProductsList({required this.products, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        44 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) =>
          _ShopProductListTile(product: products[index]),
    );
  }
}

class _ShopProductCard extends StatelessWidget {
  final Product product;

  const _ShopProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () => _openDetails(context),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.055),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductImage(product: product, height: 148),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff9A9A9A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff202020),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(child: _Price(product: product)),
                        _QuickCartButton(product: product),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }
}

class _ShopProductListTile extends StatelessWidget {
  final Product product;

  const _ShopProductListTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            _ProductImage(product: product, height: 112, width: 112),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category,
                    style: const TextStyle(
                      color: Color(0xff9A9A9A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: Color(0xff202020),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _Price(product: product)),
                      _QuickCartButton(product: product),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final Product product;
  final double height;
  final double? width;

  const _ProductImage({
    required this.product,
    required this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      margin: width == null ? const EdgeInsets.all(10) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: const Color(0xffF5F5F5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _image(),
            if (product.isOnSale)
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffFF6B6B),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '-${(product.discountPercentage ?? 0).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    final image = product.firstImage;
    if (image.startsWith('http')) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (image.startsWith('assets/')) {
      return Image.asset(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return const ColoredBox(
      color: Color(0xffF5F5F5),
      child: Center(
        child: Icon(Icons.image_outlined, color: Color(0xffBBBBBB), size: 34),
      ),
    );
  }
}

class _Price extends StatelessWidget {
  final Product product;

  const _Price({required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (product.formattedOriginalPrice != null)
          Text(
            product.formattedOriginalPrice!,
            style: const TextStyle(
              color: Color(0xffB0B0B0),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        Text(
          product.formattedPrice,
          style: const TextStyle(
            color: Color(0xff00A884),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _QuickCartButton extends StatelessWidget {
  final Product product;

  const _QuickCartButton({required this.product});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isInCart = cartProvider.isInCart(product.id);
        final isOutOfStock = !product.inStock;

        return InkWell(
          onTap: isOutOfStock
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  if (authProvider.currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please login to add to cart'),
                      ),
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
                    return;
                  }

                  cartProvider.addToCart(authProvider.currentUser!.id, product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to cart')),
                  );
                },
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOutOfStock
                  ? const Color(0xffE8E8E8)
                  : isInCart
                  ? const Color(0xffEAF7F5)
                  : const Color(0xff202020),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isOutOfStock
                  ? Icons.block_rounded
                  : isInCart
                  ? Icons.check_rounded
                  : Icons.add_rounded,
              color: isOutOfStock
                  ? const Color(0xff999999)
                  : isInCart
                  ? const Color(0xff00A884)
                  : Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyProductsState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 80),
        Container(
          width: 86,
          height: 86,
          decoration: const BoxDecoration(
            color: Color(0xffEAF7F5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.search_off_rounded,
            size: 42,
            color: Color(0xff00A884),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'No products found',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xff202020),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Try another category or adjust your filters.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xff8A8A8A),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xff202020),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text('Reload products'),
        ),
      ],
    );
  }
}
