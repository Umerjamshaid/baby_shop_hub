import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String productId;
  final String productName;
  final double rating;
  final String comment;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVerifiedPurchase;
  final List<String> helpfulVotes;
  final bool isApproved;

  Review({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.productId,
    required this.productName,
    required this.rating,
    required this.comment,
    this.imageUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.isVerifiedPurchase = false,
    this.helpfulVotes = const [],
    this.isApproved = true, // Auto-approve for now, can add moderation later
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'productId': productId,
      'productName': productName,
      'rating': rating,
      'comment': comment,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isVerifiedPurchase': isVerifiedPurchase,
      'helpfulVotes': helpfulVotes,
      'isApproved': isApproved,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userName: map['userName'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      rating: (map['rating'] as num).toDouble(),
      comment: map['comment'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      isVerifiedPurchase: map['isVerifiedPurchase'] ?? false,
      helpfulVotes: List<String>.from(map['helpfulVotes'] ?? []),
      isApproved: map['isApproved'] ?? true,
    );
  }

  // Helper to check if user has voted
  bool hasUserVoted(String userId) {
    return helpfulVotes.contains(userId);
  }

  // Helper to format date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  // Copy with method
  Review copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    String? productId,
    String? productName,
    double? rating,
    String? comment,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerifiedPurchase,
    List<String>? helpfulVotes,
    bool? isApproved,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}