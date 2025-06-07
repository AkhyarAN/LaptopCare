import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:http/http.dart' as http;
import '../data/services/appwrite_service.dart';

/// Utility class untuk membuat dan mengisi database dan koleksi Appwrite
class AppwriteCLI {
  // API key yang diberikan user
  static const String apiKey =
      'standard_c52dd8249abbdf7bcea18eb04ab265e87472b32826e09998817fdd1c8e775229cb4a941279026b7d6dbfc4172c0516d0bad59c66bf129640026ed9d9bfce251312ee453bdc8fdc02de5620e3fb8db65efc87d83220605b9ed76f70a53c8a1ff84b62ac3be8b4eea808d6057467c250f42ab160ee6a46c02a650db0ee0a3bebeb';

  // Konstanta Appwrite
  static const String endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String projectId = 'project-fra-task-management-app';
  static const String databaseId = 'laptopcare-db';

  /// Menampilkan dialog untuk memilih operasi yang ingin dilakukan
  static Future<void> showCLIDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appwrite CLI Helper'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _checkDatabase(context),
              child: const Text('Periksa Database'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _createDatabaseAndCollections(context),
              child: const Text('Buat Database & Koleksi'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _createCollectionsViaAPI(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Buat Koleksi Otomatis'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _insertSampleData(context),
              child: const Text('Isi Data Sample'),
            ),
          ],
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

  /// Memeriksa apakah database dan koleksi sudah ada
  static Future<void> _checkDatabase(BuildContext context) async {
    _showLoadingDialog(context, 'Memeriksa database...');

    try {
      final appwrite = AppwriteService();
      String result = '';

      // Cek apakah database sudah ada
      bool databaseExists = await appwrite.checkDatabaseExists();

      if (databaseExists) {
        result += '✅ Database ${AppwriteService.databaseId} sudah ada\n\n';

        // Cek koleksi users
        try {
          await appwrite.databases.listDocuments(
            databaseId: AppwriteService.databaseId,
            collectionId: AppwriteService.usersCollectionId,
            queries: [Query.limit(1)],
          );
          result +=
              '✅ Koleksi ${AppwriteService.usersCollectionId} sudah ada\n';
        } catch (e) {
          result +=
              '❌ Koleksi ${AppwriteService.usersCollectionId} belum ada: ${e.toString().split('Exception:').last}\n';
        }

        // Cek koleksi laptops
        try {
          await appwrite.databases.listDocuments(
            databaseId: AppwriteService.databaseId,
            collectionId: AppwriteService.laptopsCollectionId,
            queries: [Query.limit(1)],
          );
          result +=
              '✅ Koleksi ${AppwriteService.laptopsCollectionId} sudah ada\n';
        } catch (e) {
          result +=
              '❌ Koleksi ${AppwriteService.laptopsCollectionId} belum ada: ${e.toString().split('Exception:').last}\n';
        }

        // Cek koleksi tasks
        try {
          await appwrite.databases.listDocuments(
            databaseId: AppwriteService.databaseId,
            collectionId: AppwriteService.tasksCollectionId,
            queries: [Query.limit(1)],
          );
          result +=
              '✅ Koleksi ${AppwriteService.tasksCollectionId} sudah ada\n';
        } catch (e) {
          result +=
              '❌ Koleksi ${AppwriteService.tasksCollectionId} belum ada: ${e.toString().split('Exception:').last}\n';
        }
      } else {
        result += '❌ Database ${AppwriteService.databaseId} belum ada\n';
      }

      if (context.mounted) Navigator.pop(context); // Close loading dialog

      if (context.mounted) {
        _showResultDialog(context, 'Status Database', result);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loading dialog
      if (context.mounted) {
        _showResultDialog(context, 'Error', 'Terjadi kesalahan: $e');
      }
    }
  }

  /// Membuat database dan koleksi baru
  static Future<void> _createDatabaseAndCollections(
      BuildContext context) async {
    _showLoadingDialog(context, 'Membuat database dan koleksi...');

    try {
      final appwrite = AppwriteService();
      String result = '';

      // Cek apakah database sudah ada
      bool databaseExists = await appwrite.checkDatabaseExists();

      if (!databaseExists) {
        // Tampilkan petunjuk untuk membuat database
        result +=
            '❌ Database ${AppwriteService.databaseId} tidak dapat dibuat secara otomatis melalui Flutter SDK.\n';
        result +=
            'Silakan buat database secara manual melalui Appwrite Console dengan langkah berikut:\n\n';
        result +=
            '1. Buka Appwrite Console: https://fra.cloud.appwrite.io/console\n';
        result += '2. Pilih project Anda: ${AppwriteService.projectId}\n';
        result += '3. Pilih "Databases" di sidebar\n';
        result += '4. Klik "Create Database"\n';
        result += '5. Isi Database ID: ${AppwriteService.databaseId}\n';
        result += '6. Isi Name: "LaptopCare Database"\n';
        result += '7. Klik "Create"\n\n';

        result +=
            'Setelah membuat database, jalankan kembali "Buat Database & Koleksi" untuk membuat koleksi.\n\n';
      } else {
        result += '✅ Database ${AppwriteService.databaseId} sudah ada\n\n';

        // Buat koleksi users
        try {
          bool collectionExists = true;
          try {
            await appwrite.databases.listDocuments(
              databaseId: AppwriteService.databaseId,
              collectionId: AppwriteService.usersCollectionId,
              queries: [Query.limit(1)],
            );
          } catch (e) {
            if (e.toString().contains('collection_not_found')) {
              collectionExists = false;
            }
          }

          if (!collectionExists) {
            result += 'Membuat koleksi users...\n';
            result +=
                'Silakan buat koleksi users secara manual dengan langkah berikut:\n';
            result += '1. Buka database ${AppwriteService.databaseId}\n';
            result += '2. Klik "Create Collection"\n';
            result +=
                '3. Isi Collection ID: ${AppwriteService.usersCollectionId}\n';
            result += '4. Isi Name: "Users"\n';
            result +=
                '5. Di bagian Permissions, pilih "Any" untuk Read dan Write\n';
            result += '6. Klik "Create"\n';
            result += '7. Tambahkan atribut berikut:\n';
            result += '   - user_id (string, required, size: 36)\n';
            result += '   - email (string, required, size: 255)\n';
            result += '   - name (string, size: 255)\n';
            result += '   - created_at (string, size: 255)\n';
            result += '   - theme (string, size: 50)\n';
            result += '   - notifications_enabled (boolean)\n\n';
          } else {
            result +=
                '✅ Koleksi ${AppwriteService.usersCollectionId} sudah ada\n\n';
          }
        } catch (e) {
          result += '❌ Error saat memeriksa koleksi users: $e\n\n';
        }

        // Buat koleksi laptops
        try {
          bool collectionExists = true;
          try {
            await appwrite.databases.listDocuments(
              databaseId: AppwriteService.databaseId,
              collectionId: AppwriteService.laptopsCollectionId,
              queries: [Query.limit(1)],
            );
          } catch (e) {
            if (e.toString().contains('collection_not_found')) {
              collectionExists = false;
            }
          }

          if (!collectionExists) {
            result += 'Membuat koleksi laptops...\n';
            result +=
                'Silakan buat koleksi laptops secara manual dengan langkah berikut:\n';
            result += '1. Buka database ${AppwriteService.databaseId}\n';
            result += '2. Klik "Create Collection"\n';
            result +=
                '3. Isi Collection ID: ${AppwriteService.laptopsCollectionId}\n';
            result += '4. Isi Name: "Laptops"\n';
            result +=
                '5. Di bagian Permissions, pilih "Any" untuk Read dan Write\n';
            result += '6. Klik "Create"\n';
            result += '7. Tambahkan atribut berikut:\n';
            result += '   - laptop_id (string, required, size: 36)\n';
            result += '   - user_id (string, required, size: 36)\n';
            result += '   - name (string, required, size: 255)\n';
            result += '   - brand (string, size: 255)\n';
            result += '   - model (string, size: 255)\n';
            result += '   - purchase_date (string, size: 255)\n';
            result += '   - os (string, size: 255)\n';
            result += '   - ram (string, size: 255)\n';
            result += '   - storage (string, size: 255)\n';
            result += '   - cpu (string, size: 255)\n';
            result += '   - gpu (string, size: 255)\n';
            result += '   - image_id (string, size: 255)\n';
            result += '   - created_at (string, size: 255)\n';
            result += '   - updated_at (string, size: 255)\n\n';
          } else {
            result +=
                '✅ Koleksi ${AppwriteService.laptopsCollectionId} sudah ada\n\n';
          }
        } catch (e) {
          result += '❌ Error saat memeriksa koleksi laptops: $e\n\n';
        }

        // Buat koleksi tasks
        try {
          bool collectionExists = true;
          try {
            await appwrite.databases.listDocuments(
              databaseId: AppwriteService.databaseId,
              collectionId: AppwriteService.tasksCollectionId,
              queries: [Query.limit(1)],
            );
          } catch (e) {
            if (e.toString().contains('collection_not_found')) {
              collectionExists = false;
            }
          }

          if (!collectionExists) {
            result += 'Membuat koleksi maintenance_tasks...\n';
            result +=
                'Silakan buat koleksi maintenance_tasks secara manual dengan langkah berikut:\n';
            result += '1. Buka database ${AppwriteService.databaseId}\n';
            result += '2. Klik "Create Collection"\n';
            result +=
                '3. Isi Collection ID: ${AppwriteService.tasksCollectionId}\n';
            result += '4. Isi Name: "Maintenance Tasks"\n';
            result +=
                '5. Di bagian Permissions, pilih "Any" untuk Read dan Write\n';
            result += '6. Klik "Create"\n';
            result += '7. Tambahkan atribut berikut:\n';
            result += '   - task_id (string, required, size: 36)\n';
            result += '   - user_id (string, required, size: 36)\n';
            result += '   - laptop_id (string, required, size: 36)\n';
            result += '   - category (string, required, size: 50)\n';
            result += '   - title (string, required, size: 255)\n';
            result += '   - description (string, required, size: 1000)\n';
            result += '   - frequency (string, required, size: 50)\n';
            result += '   - priority (string, required, size: 50)\n';
            result += '   - created_at (string, size: 255)\n';
            result += '   - updated_at (string, size: 255)\n';
          } else {
            result +=
                '✅ Koleksi ${AppwriteService.tasksCollectionId} sudah ada\n\n';
          }
        } catch (e) {
          result += '❌ Error saat memeriksa koleksi tasks: $e\n\n';
        }
      }

      if (context.mounted) Navigator.pop(context); // Close loading dialog

      if (context.mounted) {
        _showResultDialog(
            context, 'Petunjuk Pembuatan Database & Koleksi', result);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loading dialog
      if (context.mounted) {
        _showResultDialog(context, 'Error', 'Terjadi kesalahan: $e');
      }
    }
  }

  /// Membuat koleksi secara otomatis menggunakan HTTP request langsung ke Appwrite API
  static Future<void> _createCollectionsViaAPI(BuildContext context) async {
    _showLoadingDialog(context, 'Membuat koleksi secara otomatis...');

    try {
      final appwrite = AppwriteService();
      String result = '';

      // Cek apakah database sudah ada
      bool databaseExists = await appwrite.checkDatabaseExists();

      if (!databaseExists) {
        result += '❌ Database $databaseId belum ada. Membuat database...\n';

        // Buat database menggunakan API langsung
        final createDbResponse = await http.post(
          Uri.parse('$endpoint/databases'),
          headers: {
            'Content-Type': 'application/json',
            'X-Appwrite-Project': projectId,
            'X-Appwrite-Key': apiKey,
          },
          body: jsonEncode({
            'databaseId': databaseId,
            'name': 'LaptopCare Database',
          }),
        );

        if (createDbResponse.statusCode == 201 ||
            createDbResponse.statusCode == 409) {
          result += '✅ Database $databaseId berhasil dibuat atau sudah ada\n\n';
          databaseExists = true;
        } else {
          result += '❌ Gagal membuat database: ${createDbResponse.body}\n';
          result += 'Status code: ${createDbResponse.statusCode}\n';
        }
      } else {
        result += '✅ Database $databaseId sudah ada\n\n';
      }

      if (databaseExists) {
        // Buat koleksi users
        result += '🔄 Membuat koleksi users...\n';
        final usersResponse = await _createCollection(
          databaseId,
          AppwriteService.usersCollectionId,
          'Users',
        );

        if (usersResponse.statusCode == 201 ||
            usersResponse.statusCode == 409) {
          result += '✅ Koleksi users berhasil dibuat atau sudah ada\n';

          // Buat atribut untuk users
          result += '🔄 Membuat atribut untuk koleksi users...\n';

          await _createAttribute(
            databaseId,
            AppwriteService.usersCollectionId,
            'user_id',
            'string',
            true,
            null,
            36,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.usersCollectionId,
            'email',
            'string',
            true,
            null,
            255,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.usersCollectionId,
            'name',
            'string',
            false,
            null,
            255,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.usersCollectionId,
            'created_at',
            'string',
            false,
            null,
            255,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.usersCollectionId,
            'theme',
            'string',
            false,
            'light',
            50,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.usersCollectionId,
            'notifications_enabled',
            'boolean',
            false,
            'true',
            null,
          );

          result += '✅ Atribut untuk koleksi users berhasil dibuat\n\n';
        } else {
          result += '❌ Gagal membuat koleksi users: ${usersResponse.body}\n';
          result += 'Status code: ${usersResponse.statusCode}\n\n';
        }

        // Buat koleksi laptops
        result += '🔄 Membuat koleksi laptops...\n';
        final laptopsResponse = await _createCollection(
          databaseId,
          AppwriteService.laptopsCollectionId,
          'Laptops',
        );

        if (laptopsResponse.statusCode == 201 ||
            laptopsResponse.statusCode == 409) {
          result += '✅ Koleksi laptops berhasil dibuat atau sudah ada\n';

          // Buat atribut untuk laptops
          result += '🔄 Membuat atribut untuk koleksi laptops...\n';

          await _createAttribute(
            databaseId,
            AppwriteService.laptopsCollectionId,
            'laptop_id',
            'string',
            true,
            null,
            36,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.laptopsCollectionId,
            'user_id',
            'string',
            true,
            null,
            36,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.laptopsCollectionId,
            'name',
            'string',
            true,
            null,
            255,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.laptopsCollectionId,
            'brand',
            'string',
            false,
            null,
            255,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.laptopsCollectionId,
            'model',
            'string',
            false,
            null,
            255,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.laptopsCollectionId,
            'purchase_date',
            'string',
            false,
            null,
            255,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.laptopsCollectionId,
            'os',
            'string',
            false,
            null,
            255,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.laptopsCollectionId,
            'ram',
            'string',
            false,
            null,
            255,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.laptopsCollectionId,
            'storage',
            'string',
            false,
            null,
            255,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.laptopsCollectionId,
            'cpu',
            'string',
            false,
            null,
            255,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.laptopsCollectionId,
            'gpu',
            'string',
            false,
            null,
            255,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.laptopsCollectionId,
            'image_id',
            'string',
            false,
            null,
            255,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.laptopsCollectionId,
            'created_at',
            'string',
            false,
            null,
            255,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.laptopsCollectionId,
            'updated_at',
            'string',
            false,
            null,
            255,
          );

          result += '✅ Atribut untuk koleksi laptops berhasil dibuat\n\n';
        } else {
          result +=
              '❌ Gagal membuat koleksi laptops: ${laptopsResponse.body}\n';
          result += 'Status code: ${laptopsResponse.statusCode}\n\n';
        }

        // Buat koleksi tasks
        result += '🔄 Membuat koleksi maintenance_tasks...\n';
        final tasksResponse = await _createCollection(
          databaseId,
          AppwriteService.tasksCollectionId,
          'Maintenance Tasks',
        );

        if (tasksResponse.statusCode == 201 ||
            tasksResponse.statusCode == 409) {
          result +=
              '✅ Koleksi maintenance_tasks berhasil dibuat atau sudah ada\n';

          // Buat atribut untuk tasks
          result += '🔄 Membuat atribut untuk koleksi maintenance_tasks...\n';

          await _createAttribute(
            databaseId,
            AppwriteService.tasksCollectionId,
            'task_id',
            'string',
            true,
            null,
            36,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.tasksCollectionId,
            'user_id',
            'string',
            true,
            null,
            36,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.tasksCollectionId,
            'laptop_id',
            'string',
            true,
            null,
            36,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.tasksCollectionId,
            'category',
            'string',
            true,
            null,
            50,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.tasksCollectionId,
            'title',
            'string',
            true,
            null,
            255,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.tasksCollectionId,
            'description',
            'string',
            true,
            null,
            1000,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.tasksCollectionId,
            'frequency',
            'string',
            true,
            null,
            50,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.tasksCollectionId,
            'priority',
            'string',
            true,
            null,
            50,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.tasksCollectionId,
            'created_at',
            'string',
            false,
            null,
            255,
          );

          await _createAttribute(
            databaseId,
            AppwriteService.tasksCollectionId,
            'updated_at',
            'string',
            false,
            null,
            255,
          );

          result +=
              '✅ Atribut untuk koleksi maintenance_tasks berhasil dibuat\n\n';
        } else {
          result +=
              '❌ Gagal membuat koleksi maintenance_tasks: ${tasksResponse.body}\n';
          result += 'Status code: ${tasksResponse.statusCode}\n\n';
        }
      }

      if (context.mounted) Navigator.pop(context); // Close loading dialog

      if (context.mounted) {
        _showResultDialog(context, 'Hasil Pembuatan Koleksi Otomatis', result);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loading dialog
      if (context.mounted) {
        _showResultDialog(context, 'Error', 'Terjadi kesalahan: $e');
      }
    }
  }

  /// Membuat koleksi menggunakan HTTP request langsung ke Appwrite API
  static Future<http.Response> _createCollection(
    String databaseId,
    String collectionId,
    String name,
  ) async {
    final url = '$endpoint/databases/$databaseId/collections';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'X-Appwrite-Project': projectId,
        'X-Appwrite-Key': apiKey,
      },
      body: jsonEncode({
        'collectionId': collectionId,
        'name': name,
        'permissions': [
          'read("any")',
          'create("any")',
          'update("any")',
          'delete("any")',
        ],
      }),
    );
    
    return response;
  }
  
  /// Membuat atribut untuk koleksi menggunakan HTTP request langsung ke Appwrite API
  static Future<http.Response> _createAttribute(
    String databaseId,
    String collectionId,
    String key,
    String type,
    bool required,
    String? defaultValue,
    int? size,
  ) async {
    final url = '$endpoint/databases/$databaseId/collections/$collectionId/attributes/$type';
    
    final Map<String, dynamic> body = {
      'key': key,
      'required': required,
    };
    
    if (defaultValue != null) {
      body['default'] = defaultValue;
    }
    
    if (size != null && type == 'string') {
      body['size'] = size;
    }
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'X-Appwrite-Project': projectId,
        'X-Appwrite-Key': apiKey,
      },
      body: jsonEncode(body),
    );
    
    // Tunggu sebentar untuk memastikan atribut dibuat dengan benar
    await Future.delayed(const Duration(milliseconds: 500));
    
    return response;
  }

  /// Mengisi data sample ke dalam koleksi
  static Future<void> _insertSampleData(BuildContext context) async {
    _showLoadingDialog(context, 'Mengisi data sample...');

    try {
      final appwrite = AppwriteService();
      String result = '';

      // Cek apakah database dan koleksi sudah ada
      bool databaseExists = await appwrite.checkDatabaseExists();

      if (!databaseExists) {
        result +=
            '❌ Database ${AppwriteService.databaseId} belum ada. Silakan buat database terlebih dahulu.\n';
      } else {
        // Cek koleksi users
        bool usersExists = true;
        try {
          await appwrite.databases.listDocuments(
            databaseId: AppwriteService.databaseId,
            collectionId: AppwriteService.usersCollectionId,
            queries: [Query.limit(1)],
          );
        } catch (e) {
          usersExists = false;
          result +=
              '❌ Koleksi ${AppwriteService.usersCollectionId} belum ada. Silakan buat koleksi terlebih dahulu.\n';
        }

        // Cek koleksi laptops
        bool laptopsExists = true;
        try {
          await appwrite.databases.listDocuments(
            databaseId: AppwriteService.databaseId,
            collectionId: AppwriteService.laptopsCollectionId,
            queries: [Query.limit(1)],
          );
        } catch (e) {
          laptopsExists = false;
          result +=
              '❌ Koleksi ${AppwriteService.laptopsCollectionId} belum ada. Silakan buat koleksi terlebih dahulu.\n';
        }

        // Cek koleksi tasks
        bool tasksExists = true;
        try {
          await appwrite.databases.listDocuments(
            databaseId: AppwriteService.databaseId,
            collectionId: AppwriteService.tasksCollectionId,
            queries: [Query.limit(1)],
          );
        } catch (e) {
          tasksExists = false;
          result +=
              '❌ Koleksi ${AppwriteService.tasksCollectionId} belum ada. Silakan buat koleksi terlebih dahulu.\n';
        }

        // Jika semua koleksi ada, tambahkan data sample
        if (usersExists && laptopsExists && tasksExists) {
          // Tambahkan data sample untuk users
          try {
            // Cek apakah sudah ada data
            final usersList = await appwrite.databases.listDocuments(
              databaseId: AppwriteService.databaseId,
              collectionId: AppwriteService.usersCollectionId,
            );

            if (usersList.documents.isEmpty) {
              // Tambahkan data sample
              const userId = 'sample-user-id';
              await appwrite.databases.createDocument(
                databaseId: AppwriteService.databaseId,
                collectionId: AppwriteService.usersCollectionId,
                documentId: userId,
                data: {
                  'user_id': userId,
                  'email': 'sample@example.com',
                  'name': 'Sample User',
                  'created_at': DateTime.now().toIso8601String(),
                  'theme': 'light',
                  'notifications_enabled': true,
                },
                permissions: [
                  Permission.read(Role.any()),
                  Permission.update(Role.any()),
                  Permission.delete(Role.any()),
                ],
              );
              result += '✅ Data sample untuk users berhasil ditambahkan\n';

              // Tambahkan data sample untuk laptops
              const laptopId = 'sample-laptop-id';
              await appwrite.databases.createDocument(
                databaseId: AppwriteService.databaseId,
                collectionId: AppwriteService.laptopsCollectionId,
                documentId: laptopId,
                data: {
                  'laptop_id': laptopId,
                  'user_id': userId,
                  'name': 'Sample Laptop',
                  'brand': 'Sample Brand',
                  'model': 'Sample Model',
                  'purchase_date': '2023-01-01',
                  'os': 'Windows 11',
                  'ram': '16GB',
                  'storage': '512GB SSD',
                  'cpu': 'Intel Core i7',
                  'gpu': 'NVIDIA GeForce RTX 3060',
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                },
                permissions: [
                  Permission.read(Role.any()),
                  Permission.update(Role.any()),
                  Permission.delete(Role.any()),
                ],
              );
              result += '✅ Data sample untuk laptops berhasil ditambahkan\n';

              // Tambahkan data sample untuk tasks
              const taskId = 'sample-task-id';
              await appwrite.databases.createDocument(
                databaseId: AppwriteService.databaseId,
                collectionId: AppwriteService.tasksCollectionId,
                documentId: taskId,
                data: {
                  'task_id': taskId,
                  'user_id': userId,
                  'laptop_id': laptopId,
                  'category': 'Cleaning',
                  'title': 'Clean Laptop Fan',
                  'description': 'Clean the laptop fan to prevent overheating',
                  'frequency': 'Monthly',
                  'priority': 'High',
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                },
                permissions: [
                  Permission.read(Role.any()),
                  Permission.update(Role.any()),
                  Permission.delete(Role.any()),
                ],
              );
              result += '✅ Data sample untuk tasks berhasil ditambahkan\n';
            } else {
              result += '✅ Data sudah ada di koleksi users\n';
            }
          } catch (e) {
            result +=
                '❌ Error saat menambahkan data sample: ${e.toString().split('Exception:').last}\n';
          }
        }
      }

      if (context.mounted) Navigator.pop(context); // Close loading dialog

      if (context.mounted) {
        _showResultDialog(context, 'Hasil Pengisian Data Sample', result);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loading dialog
      if (context.mounted) {
        _showResultDialog(context, 'Error', 'Terjadi kesalahan: $e');
      }
    }
  }

  /// Menampilkan dialog loading
  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Menampilkan dialog hasil
  static void _showResultDialog(
      BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
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

  /// Membuka URL Appwrite Console
  static void openAppwriteConsole(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buka Appwrite Console'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Buka URL berikut di browser Anda:'),
            SizedBox(height: 8),
            SelectableText('https://cloud.appwrite.io/console'),
          ],
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
