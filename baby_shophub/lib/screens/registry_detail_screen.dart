import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/registry_model.dart';
import '../models/product_model.dart';
import '../services/registry_service.dart';
import '../services/product_service.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import 'product_detail_screen.dart';

class RegistryDetailScreen extends StatefulWidget {
  final RegistryModel registry;

  const RegistryDetailScreen({super.key, required this.registry});

  @override
  State<RegistryDetailScreen> createState() => _RegistryDetailScreenState();
}

class _RegistryDetailScreenState extends State<RegistryDetailScreen> {
  late RegistryModel _registry;
  final RegistryService _registryService = RegistryService();
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _registry = widget.registry;
  }

  Future<void> _refreshRegistry() async {
    final updated = await _registryService.getRegistry(_registry.id);
    if (updated != null && mounted) {
      setState(() => _registry = updated);
    }
  }

  void _shareRegistry() {
    // In a real app, this would be a deep link
    final link = 'https://babyshophub.com/registry/${_registry.id}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registry link copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = authProvider.currentUser?.id == _registry.userId;

    // Calculate progress
    int totalWanted = 0;
    int totalPurchased = 0;
    for (var item in _registry.items) {
      totalWanted += item.quantityWanted;
      totalPurchased += item.quantityPurchased;
    }
    double progress = totalWanted > 0 ? totalPurchased / totalWanted : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_registry.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareRegistry,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRegistry,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_registry.description.isNotEmpty) ...[
                      Text(
                        _registry.description,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Event Date: ${_registry.eventDate.month}/${_registry.eventDate.day}/${_registry.eventDate.year}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _registry.isPublic ? Colors.green[50] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _registry.isPublic ? 'Public' : 'Private',
                            style: TextStyle(
                              color: _registry.isPublic ? Colors.green[700] : Colors.grey[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Gift Progress',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(Colors.purple),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalPurchased of $totalWanted items purchased',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _registry.items.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No items in this registry yet.'),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _registry.items[index];
                          return FutureBuilder<Product?>(
                            future: _productService.getProductById(item.productId),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                              }
                              
                              final product = snapshot.data!;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          product.imageUrls?.isNotEmpty == true
                                              ? product.imageUrls!.first
                                              : 'https://via.placeholder.com/80',
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              product.formattedPrice,
                                              style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Text(
                                                  'Wanted: ${item.quantityWanted}',
                                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Purchased: ${item.quantityPurchased}',
                                                  style: TextStyle(
                                                    color: item.quantityPurchased >= item.quantityWanted
                                                        ? Colors.green
                                                        : Colors.orange,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Actions
                                      if (isOwner)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () async {
                                            await _registryService.removeItemFromRegistry(_registry.id, item);
                                            _refreshRegistry();
                                          },
                                        )
                                      else
                                        ElevatedButton(
                                          onPressed: () {
                                            // Add to cart logic here
                                            // For now just navigate to product
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ProductDetailScreen(product: product),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.purple,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          child: const Text('View'),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: _registry.items.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
