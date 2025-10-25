import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic>? data;
  final DateTime sentAt;
  final List<String> readBy;
  final String? imageUrl;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    required this.sentAt,
    this.readBy = const [],
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'sentAt': sentAt.toIso8601String(),
      'readBy': readBy,
      'imageUrl': imageUrl,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    // Robust parsing of timestamp (supports Timestamp, ISO string, int)
    DateTime parsedTimestamp;
    final raw = map['timestamp'];

    if (raw == null) {
      parsedTimestamp = DateTime.now();
    } else if (raw is Timestamp) {
      parsedTimestamp = raw.toDate();
    } else if (raw is String) {
      parsedTimestamp = DateTime.tryParse(raw) ?? DateTime.now();
    } else if (raw is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(raw);
    } else {
      parsedTimestamp = DateTime.now();
    }

    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      sentAt: parsedTimestamp,
      readBy: List<String>.from(map['readBy'] ?? []),
      imageUrl: map['imageUrl'],
    );
  }

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

  // Check if read by user
  bool isReadBy(String userId) {
    return readBy.contains(userId);
  }
}
