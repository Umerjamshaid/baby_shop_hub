import 'package:baby_shophub/widgets/home/home_header.dart';
import 'package:baby_shophub/widgets/home/promo_banner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'products_list_screen.dart';
import 'orders_screen.dart';
import 'advanced_search_screen.dart';
import '../widgets/common/compact_product_card.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const HomeContent(),
    ProductsListScreen(category: 'All'),
    const CartScreen(),
    const ProfileScreen(),
    const OrdersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFAFAFA),
      body: SafeArea(child: _screens[_currentIndex]),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    const items = [
      _NavItem(Icons.home_rounded, 'Home'),
      _NavItem(Icons.shopping_bag_rounded, 'Shop'),
      _NavItem(Icons.local_mall_rounded, 'Cart'),
      _NavItem(Icons.person_rounded, 'Profile'),
      _NavItem(Icons.receipt_long_rounded, 'Orders'),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: const BoxDecoration(color: Color(0xffFAFAFA)),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = _currentIndex == index;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xffEAF7F5)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 22,
                          color: isSelected
                              ? const Color(0xff00A884)
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xff00A884)
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);
}

class AdvancedSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
      IconButton(
        icon: const Icon(Icons.tune),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdvancedSearchScreen(initialCategory: null),
            ),
          );
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return ProductsListScreen(searchQuery: query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildPopularSearches(context);
    }
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    return FutureBuilder<List<String>>(
      future: Future.delayed(
        const Duration(milliseconds: 300),
        () => productProvider.getSearchSuggestions(query),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('Error loading suggestions'));
        }
        final suggestions = snapshot.data!;
        if (suggestions.isEmpty) {
          return Center(child: Text('No suggestions for "$query"'));
        }
        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              leading: const Icon(Icons.search),
              title: Text(suggestion),
              onTap: () {
                query = suggestion;
                showResults(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPopularSearches(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: Provider.of<ProductProvider>(
        context,
        listen: false,
      ).getPopularSearches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('Error loading popular searches'));
        }
        final popularSearches = snapshot.data!;
        return ListView.builder(
          itemCount: popularSearches.length,
          itemBuilder: (context, index) {
            final search = popularSearches[index];
            return ListTile(
              leading: const Icon(Icons.trending_up),
              title: Text(search),
              onTap: () {
                query = search;
                showResults(context);
              },
            );
          },
        );
      },
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    productProvider.loadAllProducts();
    productProvider.loadFeaturedProducts();
    if (authProvider.currentUser != null) {
      cartProvider.loadUserCart(authProvider.currentUser!.id);
    }
  }

  void _navigateToProductsList(String? category) {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    if (category == null) {
      productProvider.clearFilters();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsListScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        if (productProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (productProvider.error != null) {
          return Center(child: Text('Error: ${productProvider.error}'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            _loadData();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<CartProvider>(
                  builder: (context, cart, _) {
                    return HomeHeader(
                      cartCount: cart.itemCount,
                      onCart: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CartScreen(),
                          ),
                        );
                      },
                      onSearch: () {
                        showSearch(
                          context: context,
                          delegate: AdvancedSearchDelegate(),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                PromoBanner(
                  onShopNow: () {
                    _navigateToProductsList(null);
                  },
                ),
                const SizedBox(height: 30),
                const _SectionHeader(title: 'Popular categories'),
                const SizedBox(height: 16),
                _buildCategoryGrid(),
                const SizedBox(height: 30),
                _SectionHeader(
                  title: 'Featured picks',
                  actionLabel: 'View all',
                  onAction: () {
                    _navigateToProductsList(null);
                  },
                ),
                const SizedBox(height: 16),
                _buildFeaturedProducts(productProvider),
                const SizedBox(height: 30),
                if (productProvider.recommendedProducts.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Recommended for you',
                    actionLabel: 'See all',
                    onAction: () {
                      _navigateToProductsList(null);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildRecommendedProducts(productProvider),
                  const SizedBox(height: 30),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _navigateToProductsList(null);
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xff202020),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text(
                      'Explore all products',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'name': 'Clothing', 'icon': Icons.checkroom_rounded},
      {'name': 'Toys', 'icon': Icons.smart_toy_rounded},
      {'name': 'Feeding', 'icon': Icons.restaurant_rounded},
      {'name': 'Bath', 'icon': Icons.bathtub_rounded},
      {'name': 'Sleep', 'icon': Icons.bedtime_rounded},
      {'name': 'Safety', 'icon': Icons.health_and_safety_rounded},
      {'name': 'Health', 'icon': Icons.medical_services_rounded},
      {'name': 'More', 'icon': Icons.more_horiz_rounded},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.78,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(
          context,
          category['name'] as String,
          category['icon'] as IconData,
        );
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        _navigateToProductsList(title);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xffEAF7F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 24, color: const Color(0xff00A884)),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Color(0xff202020),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts(ProductProvider productProvider) {
    final featuredProducts = productProvider.featuredProducts.take(4).toList();
    return SizedBox(
      height: 292,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: featuredProducts.length,
        itemBuilder: (context, index) {
          final product = featuredProducts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CompactProductCard(product: product),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedProducts(ProductProvider productProvider) {
    final recommendedProducts = productProvider.recommendedProducts
        .take(6)
        .toList();
    return SizedBox(
      height: 292,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recommendedProducts.length,
        itemBuilder: (context, index) {
          final product = recommendedProducts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CompactProductCard(product: product),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Color(0xff202020),
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xff00A884),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}
