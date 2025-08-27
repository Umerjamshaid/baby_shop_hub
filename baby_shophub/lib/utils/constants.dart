class AppConstants {
  // App info
  static const String appName = 'BabyShopHub';

  // Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String ordersCollection = 'orders';
  static const String cartCollection = 'cart';
  // Add to AppConstants class
  static const String reviewsCollection = 'reviews';

  // Storage paths
  static const String userImagesPath = 'user_images';
  static const String productImagesPath = 'product_images';

  // Asset paths
  static const String logoPath = 'assets/images/logo.png';
  static const String placeholderImage = 'assets/images/placeholder.png';

  // Categories
  static const List<String> productCategories = [
    'Diapers',
    'Baby Food',
    'Clothing',
    'Toys',
    'Health & Safety',
    'Feeding',
    'Nursery',
    'Bathing',
    'Strollers & Carriers',
    'Gifts'
  ];

  // Order statuses
  static const List<String> orderStatuses = [
    'Pending',
    'Confirmed',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];
}