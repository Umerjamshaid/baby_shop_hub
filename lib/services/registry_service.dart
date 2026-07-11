import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registry_model.dart';

class RegistryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'registries';

  // Create a new registry
  Future<void> createRegistry(RegistryModel registry) async {
    await _firestore.collection(_collection).doc(registry.id).set(registry.toMap());
  }

  // Get user's registries
  Stream<List<RegistryModel>> getUserRegistries(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RegistryModel.fromMap(doc.data())).toList();
    });
  }

  // Get a single registry by ID
  Future<RegistryModel?> getRegistry(String registryId) async {
    final doc = await _firestore.collection(_collection).doc(registryId).get();
    if (doc.exists) {
      return RegistryModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Add item to registry
  Future<void> addItemToRegistry(String registryId, RegistryItem item) async {
    final registryRef = _firestore.collection(_collection).doc(registryId);
    
    // Use arrayUnion to add the item
    // Note: This is a simple implementation. For updating quantities of existing items,
    // we would need a transaction or read-modify-write.
    await registryRef.update({
      'items': FieldValue.arrayUnion([item.toMap()])
    });
  }

  // Remove item from registry
  Future<void> removeItemFromRegistry(String registryId, RegistryItem item) async {
    final registryRef = _firestore.collection(_collection).doc(registryId);
    await registryRef.update({
      'items': FieldValue.arrayRemove([item.toMap()])
    });
  }

  // Update item quantity (purchased)
  Future<void> updateItemPurchased(String registryId, String productId, int quantity) async {
    // This requires a transaction to be safe
    return _firestore.runTransaction((transaction) async {
      final registryRef = _firestore.collection(_collection).doc(registryId);
      final snapshot = await transaction.get(registryRef);
      
      if (!snapshot.exists) return;

      final registry = RegistryModel.fromMap(snapshot.data()!);
      final updatedItems = registry.items.map((item) {
        if (item.productId == productId) {
          return RegistryItem(
            productId: item.productId,
            quantityWanted: item.quantityWanted,
            quantityPurchased: item.quantityPurchased + quantity,
            addedAt: item.addedAt,
          );
        }
        return item;
      }).toList();

      transaction.update(registryRef, {
        'items': updatedItems.map((x) => x.toMap()).toList(),
      });
    });
  }
}
