import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/laptop_provider.dart';
import '../../../data/services/appwrite_service.dart';
import '../../../utils/appwrite_seeder.dart';
import 'add_laptop_screen.dart';
import 'laptop_detail_screen.dart';

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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LaptopDetailScreen(laptop: laptop),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Laptop image or icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        child: laptop.imageId != null &&
                                laptop.imageId!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FutureBuilder<String>(
                                  future: AppwriteService()
                                      .getImageUrl(laptop.imageId!),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      );
                                    }

                                    if (snapshot.hasData) {
                                      debugPrint(
                                          'LaptopList - Loading image: ${snapshot.data}');
                                      return Image.network(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                        headers: const {'Accept': 'image/*'},
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          debugPrint(
                                              'LaptopList - Error loading image: $error');
                                          return const Icon(Icons.laptop_mac,
                                              size: 30, color: Colors.grey);
                                        },
                                      );
                                    }
                                    return const Icon(Icons.laptop_mac,
                                        size: 30, color: Colors.grey);
                                  },
                                ),
                              )
                            : const Icon(Icons.laptop_mac,
                                size: 30, color: Colors.grey),
                      ),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ],
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
