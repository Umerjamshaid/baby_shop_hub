import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/registry_model.dart';
import '../services/registry_service.dart';
import '../providers/auth_provider.dart';
import 'create_registry_screen.dart';
import 'registry_detail_screen.dart';

class RegistryListScreen extends StatelessWidget {
  const RegistryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final registryService = RegistryService();

    if (authProvider.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Registries')),
        body: const Center(child: Text('Please login to view your registries')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Registries'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<List<RegistryModel>>(
        stream: registryService.getUserRegistries(authProvider.currentUser!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final registries = snapshot.data ?? [];

          if (registries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No registries yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Create a registry for your baby shower or birthday!'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateRegistryScreen()),
                      );
                    },
                    child: const Text('Create Registry'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: registries.length,
            itemBuilder: (context, index) {
              final registry = registries[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.child_friendly, color: Colors.purple[400]),
                  ),
                  title: Text(
                    registry.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${registry.items.length} items • ${registry.eventDate.month}/${registry.eventDate.day}/${registry.eventDate.year}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegistryDetailScreen(registry: registry),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRegistryScreen()),
          );
        },
        label: const Text('New Registry'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.purple,
      ),
    );
  }
}
