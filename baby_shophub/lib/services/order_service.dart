import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../models/order_model.dart';
import '../utils/constants.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new order
  Future<void> createOrder(Order order) async {
    try {
      // Add initial status update
      final orderWithStatus = order.copyWith(
        statusUpdates: [
          OrderStatusUpdate(
            status: 'Pending',
            timestamp: DateTime.now(),
            message: 'Order placed successfully',
          ),
        ],
      );

      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(order.id)
          .set(orderWithStatus.toMap());
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get user orders
  // Alternative approach: Use a different field for indexing
  // Get user orders - MODIFIED VERSION (no index required)
  Future<List<Order>> getUserOrders(String userId) async {
    try {
      // First approach: Remove the ordering temporarily
      final snapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('userId', isEqualTo: userId)
          .get();

      // Sort manually on the client side
      final orders = snapshot.docs
          .map((doc) => Order.fromMap(doc.data()))
          .toList();

      // Sort by orderDate descending manually
      orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

      return orders;
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? message,
  }) async {
    try {
      final update = OrderStatusUpdate(
        status: status,
        timestamp: DateTime.now(),
        message: message,
      );

      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update({
            'status': status,
            'statusUpdates': FieldValue.arrayUnion([update.toMap()]),
          });

      // If delivered, set delivery date
      if (status == 'Delivered') {
        await _firestore
            .collection(AppConstants.ordersCollection)
            .doc(orderId)
            .update({'deliveryDate': DateTime.now().toIso8601String()});
      }
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Get order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (doc.exists) {
        return Order.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  // Cancel order
  Future<void> cancelOrder(String orderId) async {
    try {
      await updateOrderStatus(
        orderId,
        'Cancelled',
        message: 'Order cancelled by customer',
      );
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Add tracking information
  Future<void> addTrackingInfo(
    String orderId,
    String trackingNumber,
    String carrier,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update({
            'trackingNumber': trackingNumber,
            'carrier': carrier,
            'status': 'Shipped',
          });

      await updateOrderStatus(
        orderId,
        'Shipped',
        message: 'Order shipped with tracking number: $trackingNumber',
      );
    } catch (e) {
      throw Exception('Failed to add tracking info: $e');
    }
  }

  // Reorder - create a new order with same items
  Future<Order?> reorder(String orderId, String userId) async {
    try {
      final originalOrder = await getOrderById(orderId);
      if (originalOrder != null) {
        final newOrder = Order(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          items: originalOrder.items,
          totalAmount: originalOrder.totalAmount,
          status: 'Pending',
          shippingAddress: originalOrder.shippingAddress,
          orderDate: DateTime.now(),
          paymentMethod: originalOrder.paymentMethod,
        );

        await createOrder(newOrder);
        return newOrder;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to reorder: $e');
    }
  }
}
