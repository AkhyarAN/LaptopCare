import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/laptop.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/laptop_provider.dart';
import '../../../data/services/appwrite_service.dart';
import 'edit_laptop_screen.dart';

class LaptopDetailScreen extends StatelessWidget {
  final Laptop laptop;

  const LaptopDetailScreen({
    super.key,
    required this.laptop,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(laptop.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditLaptopScreen(laptop: laptop),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan gambar
            _buildHeader(context),
            const SizedBox(height: 24),

            // Basic Info
            _buildInfoSection(
              'Basic Information',
              [
                _buildInfoRow('Name', laptop.name),
                _buildInfoRow('Brand', laptop.brand ?? 'Not specified'),
                _buildInfoRow('Model', laptop.model ?? 'Not specified'),
                _buildInfoRow('Operating System', laptop.os ?? 'Not specified'),
              ],
            ),
            const SizedBox(height: 16),

            // Hardware Info
            _buildInfoSection(
              'Hardware Specifications',
              [
                _buildInfoRow('Processor (CPU)', laptop.cpu ?? 'Not specified'),
                _buildInfoRow('Graphics (GPU)', laptop.gpu ?? 'Not specified'),
                _buildInfoRow('Memory (RAM)', laptop.ram ?? 'Not specified'),
                _buildInfoRow('Storage', laptop.storage ?? 'Not specified'),
              ],
            ),
            const SizedBox(height: 16),

            // Purchase Info
            _buildInfoSection(
              'Purchase Information',
              [
                _buildInfoRow(
                  'Purchase Date',
                  laptop.purchaseDate != null
                      ? '${laptop.purchaseDate!.day}/${laptop.purchaseDate!.month}/${laptop.purchaseDate!.year}'
                      : 'Not specified',
                ),
                _buildInfoRow(
                  'Added to System',
                  '${laptop.createdAt.day}/${laptop.createdAt.month}/${laptop.createdAt.year}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Laptop image atau placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
              ),
              child: laptop.imageId != null && laptop.imageId!.isNotEmpty
                  ? ClipRoundedRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FutureBuilder<String>(
                        future: AppwriteService().getImageUrl(laptop.imageId!),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Image.network(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderIcon();
                              },
                            );
                          }
                          return _buildPlaceholderIcon();
                        },
                      ),
                    )
                  : _buildPlaceholderIcon(),
            ),
            const SizedBox(width: 16),

            // Laptop basic info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    laptop.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (laptop.brand != null || laptop.model != null)
                    Text(
                      '${laptop.brand ?? ''} ${laptop.model ?? ''}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  const SizedBox(height: 8),
                  if (laptop.os != null && laptop.os!.isNotEmpty)
                    Chip(
                      label: Text(laptop.os!),
                      avatar: const Icon(Icons.computer, size: 16),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.laptop_mac,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Laptop'),
          content: Text('Are you sure you want to delete "${laptop.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog

                await _deleteLaptop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteLaptop(BuildContext context) async {
    final laptopProvider = Provider.of<LaptopProvider>(context, listen: false);

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting laptop...')),
      );

      final success = await laptopProvider.deleteLaptop(laptop.laptopId);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laptop deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(); // Go back to list
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete laptop'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Helper widget untuk ClipRoundedRect
class ClipRoundedRect extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const ClipRoundedRect({
    super.key,
    required this.child,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: child,
    );
  }
}
