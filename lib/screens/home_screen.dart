import 'package:baby_shophub/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/notification_provider.dart';
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
      appBar: _buildAppBar(),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'BABYSHOP FORCE',
        style: TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.black),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, size: 28),
          onPressed: () {
            showSearch(context: context, delegate: AdvancedSearchDelegate());
          },
        ),
        Consumer<CartProvider>(
          builder: (context, cart, child) {
            return Badge(
              label: Text(cart.itemCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.redAccent,
              isLabelVisible: cart.itemCount > 0,
              child: IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, size: 26),
                onPressed: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                },
              ),
            );
          },
        ),
        Consumer2<AuthProvider, NotificationProvider>(
          builder: (context, authProvider, notificationProvider, _) {
            final userId = authProvider.currentUser?.id;
            final unreadCount = userId != null
                ? notificationProvider.unreadCount(userId)
                : 0;
            return Badge(
              label: Text(unreadCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.redAccent,
              isLabelVisible: unreadCount > 0,
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey.shade400,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      elevation: 16,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home, size: 28),
          label: 'HOME',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category_outlined),
          activeIcon: Icon(Icons.category, size: 28),
          label: 'SHOP',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          activeIcon: Icon(Icons.shopping_cart, size: 28),
          label: 'CART',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person, size: 28),
          label: 'PROFILE',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag, size: 28),
          label: 'ORDERS',
        ),
      ],
    );
  }
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
    return FutureBuilder<List<String>>(
      future: Future.delayed(
        const Duration(milliseconds: 300),
        () => Provider.of<ProductProvider>(
          context,
          listen: false,
        ).getSearchSuggestions(query),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPromoBanner(),
                const SizedBox(height: 24),
                const Text(
                  'CATEGORIES',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCategoryGrid(),
                const SizedBox(height: 24),
                const Text(
                  'FEATURED PRODUCTS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFeaturedProducts(productProvider),
                const SizedBox(height: 24),
                // Recommended Products Section
                if (productProvider.recommendedProducts.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RECOMMENDED',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: Colors.black,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _navigateToProductsList(null);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          'SEE ALL',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRecommendedProducts(productProvider),
                  const SizedBox(height: 24),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _navigateToProductsList(null);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'VIEW ALL PRODUCTS',
                      style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: const BoxDecoration(
        color: Colors.black, // Stark black background
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1519689680058-324335c77eba?auto=format&fit=crop&q=80&w=800',
          ),
          fit: BoxFit.cover,
          opacity: 0.5, // Darken image to make text pop
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'NEVER STOP EXPLORING',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'THE NEW\nFORCE COLLECTION',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: const Text(
                'SHOP NOW',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'name': 'CLOTHING', 'icon': Icons.checkroom},
      {'name': 'TOYS', 'icon': Icons.smart_toy},
      {'name': 'FEEDING', 'icon': Icons.restaurant},
      {'name': 'BATH', 'icon': Icons.bathtub},
      {'name': 'SLEEP', 'icon': Icons.bedtime},
      {'name': 'SAFETY', 'icon': Icons.health_and_safety},
      {'name': 'HEALTH', 'icon': Icons.medical_services},
      {'name': 'MORE', 'icon': Icons.more_horiz},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.zero, // Sharp corners
            ),
            child: Icon(icon, size: 28, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.5,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProducts(ProductProvider productProvider) {
    final featuredProducts = productProvider.featuredProducts.take(4).toList();
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: featuredProducts.length,
        itemBuilder: (context, index) {
          final product = featuredProducts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
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
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recommendedProducts.length,
        itemBuilder: (context, index) {
          final product = recommendedProducts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CompactProductCard(product: product),
          );
        },
      ),
    );
  }
}
