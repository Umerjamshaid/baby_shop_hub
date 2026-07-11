import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';

class VideoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'videos';

  // Get all active videos
  Stream<List<VideoModel>> getVideos() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => VideoModel.fromMap(doc.data())).toList();
    });
  }

  // Get videos by category
  Stream<List<VideoModel>> getVideosByCategory(String category) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => VideoModel.fromMap(doc.data())).toList();
    });
  }

  // Get trending videos (most liked/viewed)
  Future<List<VideoModel>> getTrendingVideos({int limit = 10}) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('likes', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => VideoModel.fromMap(doc.data())).toList();
  }

  // Increment view count
  Future<void> incrementViews(String videoId) async {
    await _firestore.collection(_collection).doc(videoId).update({
      'views': FieldValue.increment(1),
    });
  }

  // Toggle like
  Future<void> toggleLike(String videoId, String userId) async {
    final videoRef = _firestore.collection(_collection).doc(videoId);
    final doc = await videoRef.get();
    
    if (!doc.exists) return;

    final video = VideoModel.fromMap(doc.data()!);
    final isLiked = video.likedBy.contains(userId);

    if (isLiked) {
      await videoRef.update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    } else {
      await videoRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    }
  }

  // Increment share count
  Future<void> incrementShares(String videoId) async {
    await _firestore.collection(_collection).doc(videoId).update({
      'shares': FieldValue.increment(1),
    });
  }

  // Add video (admin only)
  Future<void> addVideo(VideoModel video) async {
    await _firestore.collection(_collection).doc(video.id).set(video.toMap());
  }

  // Delete video
  Future<void> deleteVideo(String videoId) async {
    await _firestore.collection(_collection).doc(videoId).delete();
  }
}
