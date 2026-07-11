import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String title;
  final String description;
  final String uploaderId;
  final String uploaderName;
  final String? uploaderAvatar;
  final List<String> productIds;
  final int views;
  final int likes;
  final int shares;
  final List<String> likedBy;
  final DateTime createdAt;
  final bool isActive;
  final String category;
  final List<String> tags;

  VideoModel({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.title,
    required this.description,
    required this.uploaderId,
    required this.uploaderName,
    this.uploaderAvatar,
    this.productIds = const [],
    this.views = 0,
    this.likes = 0,
    this.shares = 0,
    this.likedBy = const [],
    required this.createdAt,
    this.isActive = true,
    this.category = 'General',
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'description': description,
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'uploaderAvatar': uploaderAvatar,
      'productIds': productIds,
      'views': views,
      'likes': likes,
      'shares': shares,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'category': category,
      'tags': tags,
    };
  }

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is Timestamp) return dateValue.toDate();
      if (dateValue is String) return DateTime.tryParse(dateValue) ?? DateTime.now();
      return DateTime.now();
    }

    return VideoModel(
      id: map['id'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      uploaderId: map['uploaderId'] ?? '',
      uploaderName: map['uploaderName'] ?? 'Unknown',
      uploaderAvatar: map['uploaderAvatar'],
      productIds: List<String>.from(map['productIds'] ?? []),
      views: map['views']?.toInt() ?? 0,
      likes: map['likes']?.toInt() ?? 0,
      shares: map['shares']?.toInt() ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      createdAt: parseDate(map['createdAt']),
      isActive: map['isActive'] ?? true,
      category: map['category'] ?? 'General',
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  VideoModel copyWith({
    String? id,
    String? videoUrl,
    String? thumbnailUrl,
    String? title,
    String? description,
    String? uploaderId,
    String? uploaderName,
    String? uploaderAvatar,
    List<String>? productIds,
    int? views,
    int? likes,
    int? shares,
    List<String>? likedBy,
    DateTime? createdAt,
    bool? isActive,
    String? category,
    List<String>? tags,
  }) {
    return VideoModel(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      uploaderId: uploaderId ?? this.uploaderId,
      uploaderName: uploaderName ?? this.uploaderName,
      uploaderAvatar: uploaderAvatar ?? this.uploaderAvatar,
      productIds: productIds ?? this.productIds,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      shares: shares ?? this.shares,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      category: category ?? this.category,
      tags: tags ?? this.tags,
    );
  }
}
