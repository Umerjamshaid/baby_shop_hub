import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'subscriptions';

  // Create a new subscription
  Future<void> createSubscription(SubscriptionModel subscription) async {
    await _firestore.collection(_collection).doc(subscription.id).set(subscription.toMap());
  }

  // Get user's subscriptions
  Stream<List<SubscriptionModel>> getUserSubscriptions(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SubscriptionModel.fromMap(doc.data())).toList();
    });
  }

  // Get active subscriptions
  Stream<List<SubscriptionModel>> getActiveSubscriptions(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SubscriptionModel.fromMap(doc.data())).toList();
    });
  }

  // Update subscription
  Future<void> updateSubscription(SubscriptionModel subscription) async {
    await _firestore.collection(_collection).doc(subscription.id).update(
      subscription.copyWith(updatedAt: DateTime.now()).toMap(),
    );
  }

  // Pause subscription
  Future<void> pauseSubscription(String subscriptionId, DateTime pausedUntil) async {
    await _firestore.collection(_collection).doc(subscriptionId).update({
      'pausedUntil': Timestamp.fromDate(pausedUntil),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Resume subscription
  Future<void> resumeSubscription(String subscriptionId) async {
    await _firestore.collection(_collection).doc(subscriptionId).update({
      'pausedUntil': null,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    await _firestore.collection(_collection).doc(subscriptionId).update({
      'isActive': false,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Reactivate subscription
  Future<void> reactivateSubscription(String subscriptionId) async {
    await _firestore.collection(_collection).doc(subscriptionId).update({
      'isActive': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Update next delivery date (called after order is created)
  Future<void> updateNextDeliveryDate(String subscriptionId, DateTime nextDate) async {
    await _firestore.collection(_collection).doc(subscriptionId).update({
      'nextDeliveryDate': Timestamp.fromDate(nextDate),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Get subscriptions due for delivery
  Future<List<SubscriptionModel>> getSubscriptionsDueForDelivery() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('nextDeliveryDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .get();

    return snapshot.docs.map((doc) => SubscriptionModel.fromMap(doc.data())).toList();
  }

  // Delete subscription
  Future<void> deleteSubscription(String subscriptionId) async {
    await _firestore.collection(_collection).doc(subscriptionId).delete();
  }
}
