class Category {
  final String id;
  final String name;
  final String imageUrl;
  final int productCount;

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
}