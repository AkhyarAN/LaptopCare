import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/laptop_provider.dart';
import '../../../data/services/appwrite_service.dart';
import '../../../utils/appwrite_seeder.dart';
import '../../../utils/appwrite_cli.dart';
import 'package:appwrite/appwrite.dart';

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

  Future<void> _checkProjectStatus() async {
    try {
      final appwriteService = AppwriteService();

      // Tampilkan loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memeriksa status proyek...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Buat client baru untuk testing
      final client = Client()
        ..setEndpoint(AppwriteService.endpoint)
        ..setProject(AppwriteService.projectId)
        ..setSelfSigned(status: true);

      try {
        // Gunakan account.get() untuk memeriksa koneksi dasar
        final account = Account(client);
        try {
          await account.get();
          if (!mounted) return;

          // User logged in, tampilkan info
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Status Proyek'),
              content: const SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Project ID: ${AppwriteService.projectId}'),
                    Text('Endpoint: ${AppwriteService.endpoint}'),
                    Text('Status Koneksi: Berhasil'),
                    Text('Status: User terautentikasi'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          );
        } catch (accountError) {
          // User not logged in, try to check if project exists
          if (accountError.toString().contains('Unauthorized') ||
              accountError.toString().contains('401')) {
            // This is normal if not logged in, try to check project existence
            if (!mounted) return;

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Status Proyek'),
                content: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Project ID: ${AppwriteService.projectId}'),
                      Text('Endpoint: ${AppwriteService.endpoint}'),
                      Text('Status Koneksi: Berhasil'),
                      Text(
                          'Status: Proyek terdeteksi, tetapi user belum login'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            );
          } else if (accountError.toString().contains('project_not_found')) {
            if (!mounted) return;

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Error Detail'),
                content: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Project tidak ditemukan!',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Text('Project ID: ${AppwriteService.projectId}'),
                      Text('Endpoint: ${AppwriteService.endpoint}'),
                      SizedBox(height: 16),
                      Text('Solusi:'),
                      Text('1. Pastikan ID proyek sudah benar'),
                      Text(
                          '2. Pastikan proyek sudah dibuat di Appwrite console'),
                      Text(
                          '3. Pastikan platform Flutter sudah ditambahkan ke proyek'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            );
          } else {
            if (!mounted) return;

            // Tampilkan error detail
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Error Detail'),
                content: SingleChildScrollView(
                  child: Text(
                      'Error: $accountError\n\nProject ID: ${AppwriteService.projectId}'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;

        // Tampilkan error detail
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error Detail'),
            content: SingleChildScrollView(
              child:
                  Text('Error: $e\n\nProject ID: ${AppwriteService.projectId}'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveLaptop() async {
    debugPrint('Tombol Save ditekan');
    if (_formKey.currentState!.validate()) {
      debugPrint('Form valid, melanjutkan proses');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final laptopProvider =
          Provider.of<LaptopProvider>(context, listen: false);

      if (authProvider.currentUser != null) {
        final userId = authProvider.currentUser!.id;
        debugPrint('User ID: $userId');

        // Tampilkan loading indicator sebelum proses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menyimpan data laptop...'),
            duration: Duration(seconds: 1),
          ),
        );

        try {
          // Coba simpan langsung menggunakan AppwriteService
          debugPrint('Mencoba menyimpan langsung dengan AppwriteService');
          final appwriteService = AppwriteService();

          final laptop = await appwriteService.createLaptop(
            userId: userId,
            name: _nameController.text.trim(),
            brand: _brandController.text.trim(),
            model: _modelController.text.trim(),
            purchaseDate: _purchaseDate,
            os: _osController.text.trim(),
            ram: _ramController.text.trim(),
            storage: _storageController.text.trim(),
            cpu: _cpuController.text.trim(),
            gpu: _gpuController.text.trim(),
          );

          debugPrint('Laptop berhasil disimpan: ${laptop.laptopId}');

          // Refresh laptop list
          await laptopProvider.fetchLaptops(userId);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Laptop berhasil disimpan!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).pop();
        } catch (e) {
          debugPrint('Error langsung menyimpan laptop: $e');

          if (!mounted) return;

          // Tampilkan error yang lebih informatif
          String errorMessage = 'Error: $e';
          Color errorColor = Colors.red;

          // Berikan pesan yang lebih spesifik berdasarkan jenis error
          if (e.toString().contains('project_not_found')) {
            errorMessage =
                'Project tidak ditemukan. Periksa ID proyek di kode.';
          } else if (e.toString().contains('Database not found')) {
            errorMessage =
                'Database tidak ditemukan. Buat database di Appwrite console.';
          } else if (e.toString().contains('Collection not found')) {
            errorMessage =
                'Collection laptops tidak ditemukan. Buat collection di Appwrite console.';
          } else if (e.toString().contains('Unauthorized')) {
            errorMessage = 'Tidak terautentikasi. Pastikan Anda sudah login.';
          }

          // Tampilkan error dalam dialog untuk detail lebih lanjut
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error Menyimpan Data'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage),
                    const SizedBox(height: 16),
                    const Text('Detail Error:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(e.toString()),
                    const SizedBox(height: 16),
                    const Text('Konfigurasi:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Project ID: ${AppwriteService.projectId}'),
                    const Text('Database ID: ${AppwriteService.databaseId}'),
                    const Text(
                        'Collection ID: ${AppwriteService.laptopsCollectionId}'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
                TextButton(
                  onPressed: _checkProjectStatus,
                  child: const Text('Periksa Status Proyek'),
                ),
              ],
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: errorColor,
            ),
          );
        }
      } else {
        debugPrint('User tidak login');
      }
    } else {
      debugPrint('Form tidak valid');
    }
  }

  Future<void> _saveLaptopLocally() async {
    if (_formKey.currentState!.validate()) {
      debugPrint('Menyimpan laptop secara lokal');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final laptopProvider =
          Provider.of<LaptopProvider>(context, listen: false);

      if (authProvider.currentUser != null) {
        // Tampilkan informasi yang akan disimpan
        final data = {
          'name': _nameController.text.trim(),
          'brand': _brandController.text.trim(),
          'model': _modelController.text.trim(),
          'purchase_date': _purchaseDate?.toIso8601String() ?? '',
          'os': _osController.text.trim(),
          'ram': _ramController.text.trim(),
          'storage': _storageController.text.trim(),
          'cpu': _cpuController.text.trim(),
          'gpu': _gpuController.text.trim(),
        };

        // Tampilkan dialog konfirmasi
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Data Laptop'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Name: ${data['name']}'),
                  Text('Brand: ${data['brand']}'),
                  Text('Model: ${data['model']}'),
                  Text('Purchase Date: ${data['purchase_date']}'),
                  Text('OS: ${data['os']}'),
                  Text('RAM: ${data['ram']}'),
                  Text('Storage: ${data['storage']}'),
                  Text('CPU: ${data['cpu']}'),
                  Text('GPU: ${data['gpu']}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );

        // Beri tahu user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil disimpan secara lokal'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final laptopProvider = Provider.of<LaptopProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Laptop'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Name field
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Laptop Name',
                              hintText: 'Enter a name for your laptop',
                              prefixIcon: Icon(Icons.laptop),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a name for your laptop';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Brand field
                          TextFormField(
                            controller: _brandController,
                            decoration: const InputDecoration(
                              labelText: 'Brand',
                              hintText:
                                  'Enter the brand (e.g., Dell, HP, Apple)',
                              prefixIcon: Icon(Icons.business),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Model field
                          TextFormField(
                            controller: _modelController,
                            decoration: const InputDecoration(
                              labelText: 'Model',
                              hintText:
                                  'Enter the model (e.g., XPS 15, MacBook Pro)',
                              prefixIcon: Icon(Icons.model_training),
                              border: OutlineInputBorder(),
                            ),
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
                              hintText:
                                  'Enter the OS (e.g., Windows 11, macOS)',
                              prefixIcon: Icon(Icons.computer),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // RAM field
                          TextFormField(
                            controller: _ramController,
                            decoration: const InputDecoration(
                              labelText: 'RAM',
                              hintText: 'Enter the RAM (e.g., 16GB)',
                              prefixIcon: Icon(Icons.memory),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Storage field
                          TextFormField(
                            controller: _storageController,
                            decoration: const InputDecoration(
                              labelText: 'Storage',
                              hintText: 'Enter the storage (e.g., 512GB SSD)',
                              prefixIcon: Icon(Icons.storage),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // CPU field
                          TextFormField(
                            controller: _cpuController,
                            decoration: const InputDecoration(
                              labelText: 'CPU',
                              hintText: 'Enter the CPU (e.g., Intel Core i7)',
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
                              hintText:
                                  'Enter the GPU (e.g., NVIDIA GeForce RTX 3050)',
                              prefixIcon: Icon(Icons.videogame_asset),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  laptopProvider.isLoading ? null : _saveLaptop,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: laptopProvider.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Save Laptop',
                                      style: TextStyle(fontSize: 16)),
                            ),
                          ),

                          // Test button
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  final authProvider =
                                      Provider.of<AuthProvider>(context,
                                          listen: false);
                                  final userId = authProvider.currentUser?.id ??
                                      'test-user-id';

                                  final appwriteService = AppwriteService();
                                  final testLaptop =
                                      await appwriteService.createLaptop(
                                    userId: userId,
                                    name:
                                        "Test Laptop ${DateTime.now().millisecondsSinceEpoch}",
                                    brand: "Test Brand",
                                    model: "Test Model",
                                    purchaseDate: DateTime.now(),
                                    os: "Windows 11",
                                    ram: "16GB",
                                    storage: "512GB SSD",
                                    cpu: "Intel Core i7",
                                    gpu: "NVIDIA GeForce RTX 3060",
                                  );

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Test laptop created: ${testLaptop.laptopId}'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );

                                  // Refresh laptop list
                                  final laptopProvider =
                                      Provider.of<LaptopProvider>(context,
                                          listen: false);
                                  await laptopProvider.fetchLaptops(userId);

                                  // Kembali ke halaman sebelumnya
                                  Navigator.of(context).pop();
                                } catch (e) {
                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Error creating test laptop: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Create Test Laptop',
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
