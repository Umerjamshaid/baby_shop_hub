import 'package:baby_shophub/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product_model.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'products_list_screen.dart';
import 'orders_screen.dart';
import 'product_detail_screen.dart';
import 'advanced_search_screen.dart';
import 'video_feed_screen.dart';
import 'daily_spin_wheel_screen.dart';
import 'registry_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    ProductsListScreen(
      category: 'All',
    ), // Pass 'All' category to ensure proper loading
    const CartScreen(),
    const ProfileScreen(),
    const OrdersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _safeGetScreen(_currentIndex),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _safeGetScreen(int index) {
    if (index >= 0 && index < _screens.length) {
      return _screens[index];
    }
    return _screens[0];
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0.5,
      centerTitle: false,
      title: const Text(
        'BabyShopHub',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, size: 28),
          onPressed: () {
            showSearch(context: context, delegate: AdvancedSearchDelegate());
          },
        ),
        Consumer<CartProvider>(
          builder: (context, cart, child) {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.black54,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentIndex = 2.clamp(0, _screens.length - 1);
                    });
                  },
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        cart.itemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
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
              label: Text(unreadCount.toString()),
              isLabelVisible: unreadCount > 0,
              child: IconButton(
                icon: const Icon(Icons.notifications),
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
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex.clamp(0, _screens.length - 1),
          onTap: (index) {
            setState(() {
              _currentIndex = index.clamp(0, _screens.length - 1);
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF6B73FF),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category_outlined),
              activeIcon: Icon(Icons.category),
              label: 'Shop',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Orders',
            ),
          ],
        ),
      ),
    );
  }
}

// AdvancedSearchDelegate class
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

    // Debounce search suggestions to avoid too many API calls
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Searching...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('Error loading suggestions'));
        }
        final suggestions = snapshot.data!;
        if (suggestions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No suggestions for "$query"',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.search,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              title: Text(
                suggestion,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle:
                  query.isNotEmpty &&
                      suggestion.toLowerCase().contains(query.toLowerCase())
                  ? Text(
                      'Contains: "$query"',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    )
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () {
                  query = suggestion;
                  showResults(context);
                },
              ),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Popular Searches',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
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
              ),
            ),
          ],
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

  // Enhanced navigation method for products list
  void _navigateToProductsList(String? category) {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    if (category == null) {
      // If navigating to "All Products", clear all filters first
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
          return _buildLoadingState();
        }
        if (productProvider.error != null) {
          return _buildErrorState(productProvider.error!);
        }
        return RefreshIndicator(
          onRefresh: () async {
            _loadData();
          },
          color: const Color(0xFF6B73FF),
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPromoBanner(),
                const SizedBox(height: 24),
                
                // NEW FEATURES ROW
                Row(
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                        '🎥 Videos',
                        'Watch & Shop',
                        Colors.red,
                        () {
                          Navigator.pushNamed(context, '/video-feed');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFeatureCard(
                        '🎰 Spin',
                        'Win Rewards',
                        Colors.orange,
                        () {
                          Navigator.pushNamed(context, '/spin-wheel');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFeatureCard(
                        '🎁 Registry',
                        'Gift Lists',
                        Colors.purple,
                        () {
                          Navigator.pushNamed(context, '/registries');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildCategoryGrid(),
                const SizedBox(height: 24),
                const Text(
                  'Featured Products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildFeaturedProducts(productProvider),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B73FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _navigateToProductsList(null); // Navigate to all products
                    },
                    child: const Text(
                      'View All Products',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
      height: 150,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B73FF), Color(0xFF9575CD)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '30% OFF',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'On all baby clothing',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                Spacer(),
                Row(
                  children: [
                    Text(
                      'Shop Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'name': 'Clothing', 'icon': '👶', 'color': const Color(0xFFFF6B9D)},
      {'name': 'Toys', 'icon': '🧸', 'color': const Color(0xFFFFD93D)},
      {'name': 'Feeding', 'icon': '🍼', 'color': const Color(0xFF6B73FF)},
      {'name': 'Bath', 'icon': '🛁', 'color': const Color(0xFF9575CD)},
      {'name': 'Sleep', 'icon': '😴', 'color': const Color(0xFF4CAF50)},
      {'name': 'Safety', 'icon': '🛡️', 'color': const Color(0xFFFF9800)},
      {'name': 'Health', 'icon': '❤️', 'color': const Color(0xFFF44336)},
      {'name': 'More', 'icon': '➕', 'color': Colors.grey},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(
          context,
          category['name'] as String,
          category['icon'] as String,
          category['color'] as Color,
        );
      },
    );
  }

  // Enhanced category card with proper navigation
  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String emoji,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        _navigateToProductsList(title); // Use the enhanced navigation method
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts(ProductProvider productProvider) {
    final featuredProducts = productProvider.featuredProducts.take(4).toList();
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: featuredProducts.isEmpty ? 4 : featuredProducts.length,
        itemBuilder: (context, index) {
          if (featuredProducts.isEmpty) {
            return _buildProductPlaceholder();
          }
          final product = featuredProducts[index];
          return _buildProductItem(product);
        },
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  product.firstImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.image,
                        color: Colors.grey[400],
                        size: 40,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.formattedPrice,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B73FF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF6B73FF,
                          ).withOpacity(0.1),
                          foregroundColor: const Color(0xFF6B73FF),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // FIXED: Enhanced add to cart functionality
                          final cartProvider = Provider.of<CartProvider>(
                            context,
                            listen: false,
                          );
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          if (authProvider.currentUser != null) {
                            // Fixed the parameter order - product first, then user ID
                            cartProvider.addToCart(
                              authProvider.currentUser!.id,
                              product,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                backgroundColor: const Color(0xFF6B73FF),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            // Handle user not logged in
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please log in to add items to cart',
                                ),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(fontSize: 12),
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
    );
  }

  Widget _buildProductPlaceholder() {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              color: Colors.grey[200],
            ),
            child: Center(
              child: Icon(Icons.image, color: Colors.grey[400], size: 40),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 16, width: 100, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Container(height: 14, width: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B73FF), Color(0xFF9575CD)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B73FF).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading products...',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D2D2D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFFB347)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF8E8E93),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B73FF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                _loadData();
              },
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
