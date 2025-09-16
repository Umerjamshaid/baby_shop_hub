import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final List<String> userIds;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final DateTime sentAt;
  final List<String> readBy;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.userIds,
    this.imageUrl,
    this.data,
    required this.sentAt,
    this.readBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'userIds': userIds,
      'imageUrl': imageUrl,
      'data': data,
      'sentAt': sentAt.toIso8601String(),
      'readBy': readBy,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    // Robust parsing of sentAt (supports Timestamp, ISO string, int)
    DateTime parsedSentAt;
    final raw = map['sentAt'];

    if (raw == null) {
      parsedSentAt = DateTime.now();
    } else if (raw is Timestamp) {
      parsedSentAt = raw.toDate();
    } else if (raw is String) {
      parsedSentAt = DateTime.tryParse(raw) ?? DateTime.now();
    } else if (raw is int) {
      parsedSentAt = DateTime.fromMillisecondsSinceEpoch(raw);
    } else {
      parsedSentAt = DateTime.now();
    }

    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      userIds: List<String>.from(map['userIds'] ?? []),
      imageUrl: map['imageUrl'],
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      sentAt: parsedSentAt,
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }

  // --- Convenience helpers ---

  /// Returns true if *any* user has read this notification.
  /// (Useful if UI expects a simple `isRead` boolean.)
  bool  isReadBy(String userId) {
    return readBy.contains(userId);
  }


  /// Returns true if *no* users have read this notification.
  bool isUnreadBy(String userId) {
    return !readBy.contains(userId);
  }
  // geter for userIds
  List<String> get targetUserIds => userIds;



  /// Returns true if the specific user has read the notification.
  bool isReadByUser(String userId) => readBy.contains(userId);

  // Formatted relative date / friendly string
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(sentAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(sentAt);
    }
  }
}
