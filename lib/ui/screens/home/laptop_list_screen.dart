import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/laptop_provider.dart';
import '../../../utils/appwrite_seeder.dart';
import 'add_laptop_screen.dart';

class LaptopListScreen extends StatelessWidget {
  const LaptopListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final laptopProvider = Provider.of<LaptopProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (laptopProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (laptopProvider.laptops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.laptop_mac,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No laptops found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first laptop to get started',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddLaptopScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Laptop'),
            ),
            const SizedBox(height: 16),
            // This button is for demonstration purposes only
            // It will populate the database with sample data
            TextButton.icon(
              onPressed: () async {
                if (authProvider.currentUser != null) {
                  final userId = authProvider.currentUser!.id;

                  // Jalankan seeder untuk membuat database dan koleksi
                  await AppwriteSeeder.runSeeder(context);

                  // Refresh laptops list
                  await laptopProvider.fetchLaptops(userId);
                }
              },
              icon: const Icon(Icons.data_array),
              label: const Text('Add Sample Data (Demo)'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: laptopProvider.laptops.length,
      itemBuilder: (context, index) {
        final laptop = laptopProvider.laptops[index];
        final isSelected =
            laptopProvider.selectedLaptop?.laptopId == laptop.laptopId;

        return Card(
          elevation: isSelected ? 4 : 1,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () {
              laptopProvider.selectLaptop(laptop.laptopId);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.laptop_mac, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              laptop.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (laptop.brand != null || laptop.model != null)
                              Text(
                                '${laptop.brand ?? ''} ${laptop.model ?? ''}',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (laptop.os != null && laptop.os!.isNotEmpty)
                        Chip(
                          label: Text(laptop.os!),
                          avatar: const Icon(Icons.computer, size: 16),
                        ),
                      if (laptop.ram != null && laptop.ram!.isNotEmpty)
                        Chip(
                          label: Text(laptop.ram!),
                          avatar: const Icon(Icons.memory, size: 16),
                        ),
                      if (laptop.storage != null && laptop.storage!.isNotEmpty)
                        Chip(
                          label: Text(laptop.storage!),
                          avatar: const Icon(Icons.storage, size: 16),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
