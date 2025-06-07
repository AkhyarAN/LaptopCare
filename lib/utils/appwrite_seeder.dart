import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:uuid/uuid.dart';
import '../data/services/appwrite_service.dart';

class AppwriteSeeder {
  static const String endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String projectId = 'project-fra-task-management-app';
  static const String apiKey =
      'standard_c52dd8249abbdf7bcea18eb04ab265e87472b32826e09998817fdd1c8e775229cb4a941279026b7d6dbfc4172c0516d0bad59c66bf129640026ed9d9bfce251312ee453bdc8fdc02de5620e3fb8db65efc87d83220605b9ed76f70a53c8a1ff84b62ac3be8b4eea808d6057467c250f42ab160ee6a46c02a650db0ee0a3bebeb';
  static const String databaseId = 'laptopcare-db';
  static const String usersCollectionId = 'users';
  static const String laptopsCollectionId = 'laptops';
  static const String tasksCollectionId = 'maintenance_tasks';

  static Future<void> runSeeder(BuildContext context) async {
    try {
      // Tampilkan loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Memproses'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Sedang membuat database dan koleksi...'),
            ],
          ),
        ),
      );

      // Buat database dan koleksi
      final result = await _createDatabaseAndCollections();

      // Tutup dialog loading
      if (context.mounted) Navigator.of(context).pop();

      // Tampilkan hasil
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hasil'),
            content: SingleChildScrollView(
              child: Text(result),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Tutup dialog loading jika masih ada
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Tampilkan error
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Terjadi kesalahan: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  static Future<String> _createDatabaseAndCollections() async {
    String result = '';

    try {
      // Inisialisasi Appwrite service
      final appwrite = AppwriteService();

      // Coba buat database
      result += 'Mencoba membuat database...\n';
      try {
        // Karena SDK Flutter tidak mendukung pembuatan database melalui client,
        // kita hanya bisa memeriksa apakah database sudah ada
        bool databaseExists = await appwrite.checkDatabaseExists();

        if (databaseExists) {
          result += 'Database sudah ada, melanjutkan...\n';
        } else {
          result +=
              'Database tidak ditemukan. Silakan buat database melalui Appwrite Console.\n';
          result += 'Nama database: $databaseId\n';
          return result;
        }
      } catch (e) {
        result += 'Error saat memeriksa database: $e\n';
        return result;
      }

      // Buat collection users jika belum ada
      result += 'Mencoba membuat collection users...\n';
      try {
        // Cek apakah koleksi users sudah ada
        try {
          await appwrite.databases.listDocuments(
            databaseId: databaseId,
            collectionId: usersCollectionId,
            queries: [Query.limit(1)],
          );
          result += 'Collection users sudah ada, melanjutkan...\n';
        } catch (e) {
          if (e.toString().contains('Collection not found')) {
            result +=
                'Collection users tidak ditemukan. Silakan buat collection melalui Appwrite Console.\n';
            result += 'Nama collection: $usersCollectionId\n';
            result += 'Atribut yang diperlukan:\n';
            result += '- user_id (string, required)\n';
            result += '- email (string, required)\n';
            result += '- name (string)\n';
            result += '- created_at (string)\n';
            result += '- theme (string)\n';
            result += '- notifications_enabled (boolean)\n';
          } else {
            result += 'Error saat memeriksa collection users: $e\n';
          }
        }
      } catch (e) {
        result += 'Error saat memeriksa collection users: $e\n';
      }

      // Buat collection laptops jika belum ada
      result += 'Mencoba membuat collection laptops...\n';
      try {
        // Cek apakah koleksi laptops sudah ada
        try {
          await appwrite.databases.listDocuments(
            databaseId: databaseId,
            collectionId: laptopsCollectionId,
            queries: [Query.limit(1)],
          );
          result += 'Collection laptops sudah ada, melanjutkan...\n';
        } catch (e) {
          if (e.toString().contains('Collection not found')) {
            result +=
                'Collection laptops tidak ditemukan. Silakan buat collection melalui Appwrite Console.\n';
            result += 'Nama collection: $laptopsCollectionId\n';
            result += 'Atribut yang diperlukan:\n';
            result += '- laptop_id (string, required)\n';
            result += '- user_id (string, required)\n';
            result += '- name (string, required)\n';
            result += '- brand (string)\n';
            result += '- model (string)\n';
            result += '- purchase_date (string)\n';
            result += '- os (string)\n';
            result += '- ram (string)\n';
            result += '- storage (string)\n';
            result += '- cpu (string)\n';
            result += '- gpu (string)\n';
            result += '- image_id (string)\n';
            result += '- created_at (string)\n';
            result += '- updated_at (string)\n';
          } else {
            result += 'Error saat memeriksa collection laptops: $e\n';
          }
        }
      } catch (e) {
        result += 'Error saat memeriksa collection laptops: $e\n';
      }

      // Buat collection maintenance_tasks jika belum ada
      result += 'Mencoba membuat collection maintenance_tasks...\n';
      try {
        // Cek apakah koleksi maintenance_tasks sudah ada
        try {
          await appwrite.databases.listDocuments(
            databaseId: databaseId,
            collectionId: tasksCollectionId,
            queries: [Query.limit(1)],
          );
          result += 'Collection maintenance_tasks sudah ada, melanjutkan...\n';
        } catch (e) {
          if (e.toString().contains('Collection not found')) {
            result +=
                'Collection maintenance_tasks tidak ditemukan. Silakan buat collection melalui Appwrite Console.\n';
            result += 'Nama collection: $tasksCollectionId\n';
            result += 'Atribut yang diperlukan:\n';
            result += '- task_id (string, required)\n';
            result += '- user_id (string, required)\n';
            result += '- laptop_id (string, required)\n';
            result += '- category (string, required)\n';
            result += '- title (string, required)\n';
            result += '- description (string, required)\n';
            result += '- frequency (string, required)\n';
            result += '- priority (string, required)\n';
            result += '- created_at (string)\n';
            result += '- updated_at (string)\n';
          } else {
            result += 'Error saat memeriksa collection maintenance_tasks: $e\n';
          }
        }
      } catch (e) {
        result += 'Error saat memeriksa collection maintenance_tasks: $e\n';
      }

      // Buat data sample jika koleksi sudah ada
      result += 'Mencoba membuat data sample...\n';
      try {
        await _createSampleData(appwrite);
        result += 'Data sample berhasil dibuat\n';
      } catch (e) {
        result += 'Error saat membuat data sample: $e\n';
      }

      result +=
          '\nProses selesai! Silakan periksa database dan koleksi di Appwrite Console.';
    } catch (e) {
      result += '\nTerjadi kesalahan: $e';
    }

    return result;
  }

  static Future<void> _createSampleData(AppwriteService appwrite) async {
    try {
      // Cek apakah sudah ada data di collection users
      final usersResult = await appwrite.databases.listDocuments(
        databaseId: databaseId,
        collectionId: usersCollectionId,
      );

      if (usersResult.documents.isEmpty) {
        // Buat user sample
        final userId = const Uuid().v4();
        await appwrite.databases.createDocument(
          databaseId: databaseId,
          collectionId: usersCollectionId,
          documentId: userId,
          data: {
            'user_id': userId,
            'email': 'sample@example.com',
            'name': 'Sample User',
            'created_at': DateTime.now().toIso8601String(),
            'theme': 'light',
            'notifications_enabled': true,
          },
        );

        // Buat laptop sample untuk user tersebut
        final laptopId = const Uuid().v4();
        await appwrite.databases.createDocument(
          databaseId: databaseId,
          collectionId: laptopsCollectionId,
          documentId: laptopId,
          data: {
            'laptop_id': laptopId,
            'user_id': userId,
            'name': 'My Laptop',
            'brand': 'Dell',
            'model': 'XPS 13',
            'purchase_date': DateTime(2022, 5, 15).toIso8601String(),
            'os': 'Windows 11',
            'ram': '16GB',
            'storage': '512GB SSD',
            'cpu': 'Intel Core i7-1165G7',
            'gpu': 'Intel Iris Xe Graphics',
            'image_id': '',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        );

        // Buat task sample untuk laptop tersebut
        final taskId = const Uuid().v4();
        await appwrite.databases.createDocument(
          databaseId: databaseId,
          collectionId: tasksCollectionId,
          documentId: taskId,
          data: {
            'task_id': taskId,
            'user_id': userId,
            'laptop_id': laptopId,
            'category': 'cleaning',
            'title': 'Clean Keyboard',
            'description':
                'Clean the keyboard with compressed air and wipe with microfiber cloth',
            'frequency': 'monthly',
            'priority': 'medium',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      print('Error saat membuat data sample: $e');
      // Lanjutkan proses meskipun gagal membuat data sample
    }
  }
}
