import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/laptop.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/laptop_provider.dart';
import '../../../data/services/appwrite_service.dart';

class EditLaptopScreen extends StatefulWidget {
  final Laptop laptop;

  const EditLaptopScreen({
    super.key,
    required this.laptop,
  });

  @override
  State<EditLaptopScreen> createState() => _EditLaptopScreenState();
}

class _EditLaptopScreenState extends State<EditLaptopScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _osController;
  late final TextEditingController _ramController;
  late final TextEditingController _storageController;
  late final TextEditingController _cpuController;
  late final TextEditingController _gpuController;

  DateTime? _purchaseDate;
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  String? _currentImageId;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint(
        'EditLaptopScreen: Initializing with laptop: ${widget.laptop.name}');

    try {
      // Initialize controllers with existing data
      _nameController = TextEditingController(text: widget.laptop.name);
      _brandController = TextEditingController(text: widget.laptop.brand ?? '');
      _modelController = TextEditingController(text: widget.laptop.model ?? '');
      _osController = TextEditingController(text: widget.laptop.os ?? '');
      _ramController = TextEditingController(text: widget.laptop.ram ?? '');
      _storageController =
          TextEditingController(text: widget.laptop.storage ?? '');
      _cpuController = TextEditingController(text: widget.laptop.cpu ?? '');
      _gpuController = TextEditingController(text: widget.laptop.gpu ?? '');

      _purchaseDate = widget.laptop.purchaseDate;
      _currentImageId = widget.laptop.imageId;

      debugPrint('EditLaptopScreen: Controllers initialized successfully');
    } catch (e) {
      debugPrint('EditLaptopScreen: Error in initState: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize form: $e';
      });
    }
  }

  @override
  void dispose() {
    debugPrint('EditLaptopScreen: Disposing controllers');
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
    try {
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
    } catch (e) {
      debugPrint('Error selecting date: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      debugPrint('Image picker: Starting image selection');

      // For web, we need to be more careful with image picker
      if (kIsWeb) {
        // Show a warning for web users
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

      if (image != null) {
        debugPrint('Image picker: Image selected, reading bytes...');
        final bytes = await image.readAsBytes();
        debugPrint('Image picker: Bytes read, size: ${bytes.length}');

        if (mounted) {
          setState(() {
            _selectedImage = image;
            _imageBytes = bytes;
          });
          debugPrint('Image picker: State updated successfully');
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
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
    try {
      setState(() {
        _selectedImage = null;
        _imageBytes = null;
        _currentImageId = null;
      });
    } catch (e) {
      debugPrint('Error removing image: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null || _selectedImage == null) return _currentImageId;

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
      debugPrint('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return _currentImageId;
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _saveLaptop() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final laptopProvider = Provider.of<LaptopProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Upload image if new image selected
      final imageId = await _uploadImage();

      // Create updated laptop object
      final updatedLaptop = widget.laptop.copyWith(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        model: _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        purchaseDate: _purchaseDate,
        os: _osController.text.trim().isEmpty
            ? null
            : _osController.text.trim(),
        ram: _ramController.text.trim().isEmpty
            ? null
            : _ramController.text.trim(),
        storage: _storageController.text.trim().isEmpty
            ? null
            : _storageController.text.trim(),
        cpu: _cpuController.text.trim().isEmpty
            ? null
            : _cpuController.text.trim(),
        gpu: _gpuController.text.trim().isEmpty
            ? null
            : _gpuController.text.trim(),
        imageId: imageId,
        updatedAt: DateTime.now(),
      );

      final success = await laptopProvider.updateLaptop(updatedLaptop);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laptop updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      } else if (mounted) {
        final errorMessage = laptopProvider.error ?? 'Failed to update laptop';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving laptop: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('EditLaptopScreen: Building UI');

    // If there's an error during initialization, show error screen
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Laptop')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading edit screen:',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_errorMessage ?? 'Unknown error',
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    try {
      final laptopProvider = Provider.of<LaptopProvider>(context);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Laptop'),
          actions: [
            TextButton(
              onPressed:
                  laptopProvider.isLoading || _isUploading ? null : _saveLaptop,
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Debug info
                if (kDebugMode)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Debug: Editing ${widget.laptop.name}\nCurrent image ID: ${_currentImageId ?? "none"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),

                // Image picker section
                _buildImageSection(),
                const SizedBox(height: 24),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Laptop Name *',
                    hintText: 'Enter a name for your laptop',
                    prefixIcon: Icon(Icons.laptop),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name for your laptop';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Brand and Model row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'Brand',
                          hintText: 'e.g., Dell, HP, Apple',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          hintText: 'e.g., XPS 15, MacBook Pro',
                          prefixIcon: Icon(Icons.model_training),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Purchase date field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Purchase Date'),
                    subtitle: Text(
                      _purchaseDate != null
                          ? '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'
                          : 'Select purchase date',
                    ),
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(height: 16),

                // OS field
                TextFormField(
                  controller: _osController,
                  decoration: const InputDecoration(
                    labelText: 'Operating System',
                    hintText: 'e.g., Windows 11, macOS, Ubuntu',
                    prefixIcon: Icon(Icons.computer),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Hardware specs row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ramController,
                        decoration: const InputDecoration(
                          labelText: 'RAM',
                          hintText: 'e.g., 16GB',
                          prefixIcon: Icon(Icons.memory),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _storageController,
                        decoration: const InputDecoration(
                          labelText: 'Storage',
                          hintText: 'e.g., 512GB SSD',
                          prefixIcon: Icon(Icons.storage),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CPU field
                TextFormField(
                  controller: _cpuController,
                  decoration: const InputDecoration(
                    labelText: 'CPU',
                    hintText: 'e.g., Intel Core i7-11800H',
                    prefixIcon: Icon(Icons.developer_board),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // GPU field
                TextFormField(
                  controller: _gpuController,
                  decoration: const InputDecoration(
                    labelText: 'GPU',
                    hintText: 'e.g., NVIDIA GeForce RTX 3050',
                    prefixIcon: Icon(Icons.videogame_asset),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: laptopProvider.isLoading || _isUploading
                        ? null
                        : _saveLaptop,
                    child: laptopProvider.isLoading || _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Update Laptop',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building EditLaptopScreen: $e');
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Laptop')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error building screen: $e'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildImageSection() {
    try {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Laptop Image',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _buildImagePreview(),
                ),
              ),
              const SizedBox(height: 16),

              // Button section with better error handling
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: Text(kIsWeb ? 'Choose Image (Web)' : 'Choose Image'),
                  ),
                  if (_selectedImage != null || _currentImageId != null)
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _removeImage,
                      icon: const Icon(Icons.delete),
                      label: const Text('Remove'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),

              if (kIsWeb)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Note: Image selection on web browsers may have limitations',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building image section: $e');
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Error loading image section'),
              Text('$e', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildImagePreview() {
    try {
      if (_isUploading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_imageBytes != null) {
        // Show new selected image
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _imageBytes!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error displaying selected image: $error');
              return _buildPlaceholder();
            },
          ),
        );
      }

      if (_currentImageId != null && _currentImageId!.isNotEmpty) {
        // Show existing image from Appwrite with better error handling
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FutureBuilder<String>(
            future: AppwriteService().getImageUrl(_currentImageId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                debugPrint('Error loading image URL: ${snapshot.error}');
                return _buildImageError(
                    'Failed to get image URL: ${snapshot.error}');
              }

              if (snapshot.hasData) {
                debugPrint('Loading image from URL: ${snapshot.data}');
                return Image.network(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  headers: {
                    'Accept': 'image/*',
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading network image: $error');
                    debugPrint('Stack trace: $stackTrace');
                    return _buildImageError('Image load failed: $error');
                  },
                );
              }

              return _buildPlaceholder();
            },
          ),
        );
      }

      return _buildPlaceholder();
    } catch (e) {
      debugPrint('Error in _buildImagePreview: $e');
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.laptop_mac, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No image selected', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageError(String errorMessage) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 8),
            Text(
              'Image Error',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  errorMessage,
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
 