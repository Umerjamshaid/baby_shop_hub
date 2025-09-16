class AppConstants {
  // App info
  static const String appName = 'BabyShopHub';

  // Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String ordersCollection = 'orders';
  static const String cartCollection = 'cart';
  static const String reviewsCollection = 'reviews'; // ✅ keep this
  static const String notificationsCollection = 'notifications'; // ✅ added

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
    'Gifts',
  ];

  // Order statuses
  static const List<String> orderStatuses = [
    'Pending',
    'Confirmed',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  // Filter options
  static const List<String> sortOptions = [
    'Relevance',
    'Price: Low to High',
    'Price: High to Low',
    'Highest Rated',
    'Newest First',
    'Name (A-Z)',
    'Biggest Discount',
  ];

  // Age ranges
  static const List<String> ageRanges = [
    'Newborn (0-3M)',
    '3-6 Months',
    '6-9 Months',
    '9-12 Months',
    '12-18 Months',
    '18-24 Months',
    '2-3 Years',
    '3-4 Years',
    '4+ Years',
  ];

  // Sizes
  static const List<String> sizes = [
    'Newborn',
    '0-3M',
    '3-6M',
    '6-9M',
    '9-12M',
    '12-18M',
    '18-24M',
    '2T',
    '3T',
    '4T',
    '5T',
  ];

  // Colors
  static const List<String> colors = [
    'White',
    'Black',
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Pink',
    'Purple',
    'Orange',
    'Brown',
    'Gray',
    'Multi-color',
  ];

  // Materials
  static const List<String> materials = [
    'Cotton',
    'Organic Cotton',
    'Polyester',
    'Bamboo',
    'Wool',
    'Linen',
    'Denim',
    'Fleece',
    'Microfiber',
    'Spandex',
  ];
}
