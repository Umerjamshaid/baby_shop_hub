import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDate(dynamic dateValue, {DateTime? defaultValue}) {
  if (dateValue == null) return defaultValue ?? DateTime.now();
  if (dateValue is Timestamp) return dateValue.toDate();
  if (dateValue is String) return DateTime.tryParse(dateValue) ?? defaultValue ?? DateTime.now();
  return defaultValue ?? DateTime.now();
}

class RegistryItem {
  final String productId;
  final int quantityWanted;
  final int quantityPurchased;
  final DateTime addedAt;

  RegistryItem({
    required this.productId,
    required this.quantityWanted,
    this.quantityPurchased = 0,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'quantityWanted': quantityWanted,
      'quantityPurchased': quantityPurchased,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  factory RegistryItem.fromMap(Map<String, dynamic> map) {
    return RegistryItem(
      productId: map['productId'] ?? '',
      quantityWanted: map['quantityWanted']?.toInt() ?? 1,
      quantityPurchased: map['quantityPurchased']?.toInt() ?? 0,
      addedAt: _parseDate(map['addedAt']),
    );
  }
}

class RegistryModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime eventDate;
  final bool isPublic;
  final List<RegistryItem> items;
  final DateTime createdAt;
  final String? shareLink;

  RegistryModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.eventDate,
    this.isPublic = true,
    this.items = const [],
    required this.createdAt,
    this.shareLink,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'eventDate': Timestamp.fromDate(eventDate),
      'isPublic': isPublic,
      'items': items.map((x) => x.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'shareLink': shareLink,
    };
  }

  factory RegistryModel.fromMap(Map<String, dynamic> map) {
    return RegistryModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      eventDate: _parseDate(map['eventDate']),
      isPublic: map['isPublic'] ?? true,
      items: List<RegistryItem>.from(
        (map['items'] as List<dynamic>? ?? []).map<RegistryItem>(
          (x) => RegistryItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
      createdAt: _parseDate(map['createdAt']),
      shareLink: map['shareLink'],
    );
  }
}
