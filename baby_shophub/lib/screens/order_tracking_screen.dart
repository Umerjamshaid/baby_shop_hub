import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../models/order_model.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Order order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Tracking'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info Card
            _buildOrderInfoCard(),
            const SizedBox(height: 24),

            // Tracking Information
            if (widget.order.trackingNumber != null) ...[
              _buildTrackingInfoCard(),
              const SizedBox(height: 24),
            ],

            // Status Timeline
            _buildStatusTimeline(),
            const SizedBox(height: 24),

            // Delivery Information
            if (widget.order.deliveryDate != null) _buildDeliveryInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${widget.order.id.substring(widget.order.id.length - 8).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.order.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.order.statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    widget.order.status,
                    style: TextStyle(
                      color: widget.order.statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Ordered on ${DateFormat('MMM dd, yyyy').format(widget.order.orderDate)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.shopping_bag, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${widget.order.itemCount} item${widget.order.itemCount > 1 ? 's' : ''} • ${widget.order.formattedTotalAmount}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Tracking Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Tracking Number: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        widget.order.trackingNumber!,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (widget.order.carrier != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Carrier: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(widget.order.carrier!),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    // Get status updates or create default timeline
    final statusUpdates = widget.order.statusUpdates.isNotEmpty
        ? widget.order.statusUpdates
        : _getDefaultStatusUpdates();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Timeline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...statusUpdates.asMap().entries.map((entry) {
              final index = entry.key;
              final update = entry.value;
              final isLast = index == statusUpdates.length - 1;
              final isCompleted = update.timestamp.isBefore(DateTime.now());

              return TimelineTile(
                alignment: TimelineAlign.manual,
                lineXY: 0.1,
                isLast: isLast,
                indicatorStyle: IndicatorStyle(
                  width: 20,
                  color: isCompleted ? Colors.green : Colors.grey,
                  indicatorXY: 0.0,
                  drawGap: true,
                ),
                beforeLineStyle: LineStyle(
                  color: isCompleted ? Colors.green : Colors.grey.shade300,
                  thickness: 2,
                ),
                endChild: Container(
                  margin: const EdgeInsets.only(left: 16, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatStatus(update.status),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'MMM dd, yyyy • hh:mm a',
                        ).format(update.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (update.message != null &&
                          update.message!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          update.message!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Delivery Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Estimated Delivery: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        DateFormat(
                          'MMM dd, yyyy',
                        ).format(widget.order.deliveryDate!),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your order will be delivered to:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.order.shippingAddress.displayAddress,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<OrderStatusUpdate> _getDefaultStatusUpdates() {
    final now = DateTime.now();
    final statuses = [
      'Pending',
      'Confirmed',
      'Processing',
      'Shipped',
      'Delivered',
    ];

    final currentStatusIndex = statuses.indexOf(widget.order.status);
    final updates = <OrderStatusUpdate>[];

    for (int i = 0; i <= currentStatusIndex; i++) {
      final status = statuses[i];
      final timestamp = i == currentStatusIndex
          ? now
          : now.subtract(Duration(days: currentStatusIndex - i));

      updates.add(
        OrderStatusUpdate(
          status: status,
          timestamp: timestamp,
          message: _getStatusMessage(status),
        ),
      );
    }

    return updates;
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'Pending':
        return 'Order Placed';
      case 'Confirmed':
        return 'Order Confirmed';
      case 'Processing':
        return 'Processing Order';
      case 'Shipped':
        return 'Order Shipped';
      case 'Delivered':
        return 'Order Delivered';
      default:
        return status;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'Pending':
        return 'Your order has been received and is being processed.';
      case 'Confirmed':
        return 'Your order has been confirmed and payment processed.';
      case 'Processing':
        return 'We are preparing your order for shipment.';
      case 'Shipped':
        return 'Your order has been shipped and is on its way.';
      case 'Delivered':
        return 'Your order has been successfully delivered.';
      default:
        return '';
    }
  }
}
