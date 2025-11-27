import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String unit;
  final double taxRate;
  final String category;
  final String? sku;
  final int stockQuantity;
  final bool isService;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Additional fields used throughout the app
  final List<String>? imageUrls;
  final String? brand;
  final String? ageRange;
  final double? rating;
  final int? reviewCount;
  final bool? isFeatured;
  final List<String>? sizes;
  final List<String>? colors;
  final List<String>? materials;
  final bool? isEcoFriendly;
  final bool? isOrganic;
  final double? discountPercentage;
  final double? weight;
  final double? length;
  final double? width;
  final double? height;
  final List<String>? tags;
  final String? warranty;
  final String? originCountry;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.taxRate,
    required this.category,
    this.sku,
    required this.stockQuantity,
    required this.isService,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    // Additional fields used throughout the app
    this.imageUrls,
    this.brand,
    this.ageRange,
    this.rating,
    this.reviewCount,
    this.isFeatured,
    this.sizes,
    this.colors,
    this.materials,
    this.isEcoFriendly,
    this.isOrganic,
    this.discountPercentage,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.tags,
    this.warranty,
    this.originCountry,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product.fromMap(json, json['id'] ?? '');
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      }
      if (dateValue is String) {
        return DateTime.tryParse(dateValue);
      }
      return null;
    }

    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'item',
      taxRate: (map['taxRate'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      sku: map['sku'],
      stockQuantity: map['stockQuantity'] ?? 0,
      isService: map['isService'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      brand: map['brand'],
      ageRange: map['ageRange'],
      rating: map['rating']?.toDouble(),
      reviewCount: map['reviewCount'],
      isFeatured: map['isFeatured'] ?? false,
      sizes: List<String>.from(map['sizes'] ?? []),
      colors: List<String>.from(map['colors'] ?? []),
      materials: List<String>.from(map['materials'] ?? []),
      isEcoFriendly: map['isEcoFriendly'] ?? false,
      isOrganic: map['isOrganic'] ?? false,
      discountPercentage: map['discountPercentage']?.toDouble(),
      weight: map['weight']?.toDouble(),
      length: map['length']?.toDouble(),
      width: map['width']?.toDouble(),
      height: map['height']?.toDouble(),
      tags: List<String>.from(map['tags'] ?? []),
      warranty: map['warranty'],
      originCountry: map['originCountry'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'taxRate': taxRate,
      'category': category,
      'sku': sku,
      'stockQuantity': stockQuantity,
      'isService': isService,
      'isActive': isActive,
      'imageUrls': imageUrls,
      'brand': brand,
      'ageRange': ageRange,
      'rating': rating,
      'reviewCount': reviewCount,
      'isFeatured': isFeatured,
      'sizes': sizes,
      'colors': colors,
      'materials': materials,
      'isEcoFriendly': isEcoFriendly,
      'isOrganic': isOrganic,
      'discountPercentage': discountPercentage,
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
      'tags': tags,
      'warranty': warranty,
      'originCountry': originCountry,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? unit,
    double? taxRate,
    String? category,
    String? sku,
    int? stockQuantity,
    bool? isService,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? imageUrls,
    String? brand,
    String? ageRange,
    double? rating,
    int? reviewCount,
    bool? isFeatured,
    List<String>? sizes,
    List<String>? colors,
    List<String>? materials,
    bool? isEcoFriendly,
    bool? isOrganic,
    double? discountPercentage,
    double? weight,
    double? length,
    double? width,
    double? height,
    List<String>? tags,
    String? warranty,
    String? originCountry,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      taxRate: taxRate ?? this.taxRate,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isService: isService ?? this.isService,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrls: imageUrls ?? this.imageUrls,
      brand: brand ?? this.brand,
      ageRange: ageRange ?? this.ageRange,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFeatured: isFeatured ?? this.isFeatured,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      materials: materials ?? this.materials,
      isEcoFriendly: isEcoFriendly ?? this.isEcoFriendly,
      isOrganic: isOrganic ?? this.isOrganic,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      weight: weight ?? this.weight,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      tags: tags ?? this.tags,
      warranty: warranty ?? this.warranty,
      originCountry: originCountry ?? this.originCountry,
    );
  }

  // Computed properties
  String get firstImage =>
      imageUrls?.isNotEmpty == true ? imageUrls!.first : '';

  String get formattedPrice {
    final discountedPrice = price * (1 - (discountPercentage ?? 0) / 100);
    return '\$${discountedPrice.toStringAsFixed(2)}';
  }

  String? get formattedOriginalPrice {
    if (discountPercentage == null || discountPercentage == 0) return null;
    return '\$${price.toStringAsFixed(2)}';
  }

  bool get inStock => stockQuantity > 0;

  int get stock => stockQuantity;

  bool get isOnSale => discountPercentage != null && discountPercentage! > 0;
}
