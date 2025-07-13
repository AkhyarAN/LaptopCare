import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/laptop_provider.dart';
import '../../../data/services/appwrite_service.dart';

class AddLaptopScreen extends StatefulWidget {
  const AddLaptopScreen({super.key});

  @override
  State<AddLaptopScreen> createState() => _AddLaptopScreenState();
}

class _AddLaptopScreenState extends State<AddLaptopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _osController = TextEditingController();
  final _ramController = TextEditingController();
  final _storageController = TextEditingController();
  final _cpuController = TextEditingController();
  final _gpuController = TextEditingController();

  DateTime? _purchaseDate;
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _osController.dispose();
    _ramController.dispose();
    _storageController.dispose();
    _cpuController.dispose();
    _gpuController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      // Web warning dialog
      if (kIsWeb) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Image Selection'),
            content: const Text(
                'Image selection on web may have limitations. Continue?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  }

  Future<void> _removeImage() async {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
    });
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null || _selectedImage == null) return null;

    try {
      setState(() {
        _isUploading = true;
      });

          final appwriteService = AppwriteService();
      final file = await appwriteService.uploadImage(
        _imageBytes!,
        _selectedImage!.name,
      );

      return file.$id;
        } catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
            ),
          );
      }
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _saveLaptop() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final laptopProvider = Provider.of<LaptopProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = authProvider.currentUser!.id;

    try {
      // Upload image first if selected
      final imageId = await _uploadImage();

      final success = await laptopProvider.createLaptop(
        userId: userId,
        name: _nameController.text.trim(),
        brand: _brandController.text.trim().isNotEmpty
            ? _brandController.text.trim()
            : null,
        model: _modelController.text.trim().isNotEmpty
            ? _modelController.text.trim()
            : null,
        purchaseDate: _purchaseDate,
        os: _osController.text.trim().isNotEmpty
            ? _osController.text.trim()
            : null,
        ram: _ramController.text.trim().isNotEmpty
            ? _ramController.text.trim()
            : null,
        storage: _storageController.text.trim().isNotEmpty
            ? _storageController.text.trim()
            : null,
        cpu: _cpuController.text.trim().isNotEmpty
            ? _cpuController.text.trim()
            : null,
        gpu: _gpuController.text.trim().isNotEmpty
            ? _gpuController.text.trim()
            : null,
        imageId: imageId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laptop saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(laptopProvider.error ?? 'Failed to save laptop'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Laptop'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
              Text(
                'Add New Laptop',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Image Section
              _buildImageSection(),
              const SizedBox(height: 20),

              // Name field (Required)
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                  labelText: 'Laptop Name *',
                  hintText: 'Enter laptop name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                    return 'Please enter laptop name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Brand field
                          TextFormField(
                            controller: _brandController,
                            decoration: const InputDecoration(
                  labelText: 'Brand (Optional)',
                  hintText: 'e.g., Dell, HP, Apple, ASUS',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Model field
                          TextFormField(
                            controller: _modelController,
                            decoration: const InputDecoration(
                  labelText: 'Model (Optional)',
                  hintText: 'e.g., XPS 15, MacBook Pro, ThinkPad',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

              // Purchase Date field
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                                _purchaseDate != null
                              ? 'Purchase Date: ${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'
                              : 'Select Purchase Date (Optional)',
                          style: TextStyle(
                            color: _purchaseDate != null
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // OS field
                          TextFormField(
                            controller: _osController,
                            decoration: const InputDecoration(
                  labelText: 'Operating System (Optional)',
                  hintText: 'e.g., Windows 11, macOS Ventura, Ubuntu',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // RAM field
                          TextFormField(
                            controller: _ramController,
                            decoration: const InputDecoration(
                  labelText: 'RAM (Optional)',
                  hintText: 'e.g., 16GB, 32GB DDR4',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Storage field
                          TextFormField(
                            controller: _storageController,
                            decoration: const InputDecoration(
                  labelText: 'Storage (Optional)',
                  hintText: 'e.g., 512GB SSD, 1TB NVMe',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // CPU field
                          TextFormField(
                            controller: _cpuController,
                            decoration: const InputDecoration(
                  labelText: 'CPU (Optional)',
                  hintText: 'e.g., Intel Core i7-12700H, AMD Ryzen 7',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // GPU field
                          TextFormField(
                            controller: _gpuController,
                            decoration: const InputDecoration(
                  labelText: 'GPU (Optional)',
                  hintText: 'e.g., RTX 3060, Intel Iris Xe, M1 Pro',
                              border: OutlineInputBorder(),
                            ),
                          ),
              const SizedBox(height: 30),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                child: Consumer<LaptopProvider>(
                  builder: (context, laptopProvider, child) {
                    return ElevatedButton(
                      onPressed: (laptopProvider.isLoading || _isUploading)
                          ? null
                          : _saveLaptop,
                      style: Theme.of(context).elevatedButtonTheme.style,
                      child: (laptopProvider.isLoading || _isUploading)
                          ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Save Laptop',
                                      style: TextStyle(fontSize: 16)),
                    );
                  },
                          ),
              ),
              const SizedBox(height: 20),
            ],
                                    ),
        ),
                                    ),
                                  );
                                }

  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Laptop Image (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _buildImagePreview(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: Text(kIsWeb ? 'Choose (Web)' : 'Choose'),
                              ),
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _removeImage,
                      icon: const Icon(Icons.delete),
                      label: const Text('Remove'),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            ),
                          ),
                        ],
              ],
                    ),
          ],
                ),
              ),
            );
  }

  Widget _buildImagePreview() {
    if (_isUploading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          _imageBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.laptop_mac, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('No image',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
