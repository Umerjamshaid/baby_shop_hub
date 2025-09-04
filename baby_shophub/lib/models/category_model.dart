class Category {
  final String id;
  final String name;
  final String imageUrl;
  late final int productCount;

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.productCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'productCount': productCount,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      productCount: map['productCount']?.toInt() ?? 0,
    );
  }
  // Add copyWith method
  Category copyWith({
    String? id,
    String? name,
    String? imageUrl,
    int? productCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      productCount: productCount ?? this.productCount,
    );
  }
}
