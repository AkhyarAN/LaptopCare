import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as Models;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/user.dart';
import '../models/laptop.dart';
import '../models/maintenance_task.dart';
import '../models/maintenance_history.dart';
import '../models/reminder.dart';
import '../models/guide.dart';
import '../../web_auth_helper.dart';

/// Custom Appwrite Account client that overrides OAuth methods
class CustomAccount extends Account {
  CustomAccount(Client client) : super(client);

  @override
  Future<Models.Token> createOAuth2Token({
    required String provider,
    String? success,
    String? failure,
    List<String>? scopes,
  }) async {
    final params = {
      'provider': provider,
      'success': success,
      'failure': failure,
      'scopes': scopes,
      'project': client.config['project'],
    }..removeWhere((key, value) => value == null);

    final uri = Uri.parse(client.endPoint + '/account/tokens/oauth2')
        .replace(queryParameters: params as Map<String, String>?);

    // Use our custom WebAuthHelper instead of flutter_web_auth_2
    final url = uri.toString();
    final callbackUrlScheme = 'appwrite-callback-${client.config['project']}';

    try {
      final response = await WebAuthHelper.authenticate(
        url: url,
        callbackUrlScheme: callbackUrlScheme,
      );

      // Since we don't have a real OAuth response, we'll throw an error
      // telling the user to use email/password authentication instead
      throw UnsupportedError(
          'OAuth authentication is currently not supported due to compatibility issues. ' +
              'Please use email/password authentication instead.');
    } catch (e) {
      rethrow;
    }
  }
}

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();

  // Appwrite SDK clients
  late Client client;
  late Account account;
  late Databases databases;
  late Storage storage;
  late Realtime realtime;

  // Appwrite project constants
  static const String endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String projectId = 'project-fra-task-management-app';
  static const String databaseId = 'laptopcare-db';
  static const String usersCollectionId = 'users';
  static const String laptopsCollectionId = 'laptops';
  static const String tasksCollectionId = 'maintenance_tasks';
  static const String historyCollectionId = 'maintenance_history';
  static const String remindersCollectionId = 'reminders';
  static const String guidesCollectionId = 'guides';
  static const String guideImagesCollectionId = 'guide_images';
  static const String storageId = 'laptopcare-storage';

  factory AppwriteService() => _instance;

  AppwriteService._internal() {
    // Initialize Appwrite clients
    debugPrint('Initializing Appwrite with project ID: $projectId');
    client = Client();
    client.setEndpoint(endpoint);
    client.setProject(projectId);

    // Important: Disable self-signed certs in production
    // Only use this in development
    client.setSelfSigned(status: true);

    // Use our custom Account implementation that overrides OAuth methods
    account = CustomAccount(client);
    databases = Databases(client);
    storage = Storage(client);
    realtime = Realtime(client);
  }

  // Initialize Appwrite SDK clients
  Future<void> init() async {
    debugPrint('Initializing Appwrite with project ID: $projectId');
    client = Client();
    client.setEndpoint(endpoint);
    client.setProject(projectId);
    client.setSelfSigned(
        status: true); // For self-signed certificates in dev mode

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    realtime = Realtime(client);

    debugPrint('Appwrite SDK clients initialized');
  }

  // Database initialization and connectivity check
  Future<void> initializeDatabase() async {
    try {
      debugPrint('🔍 Checking database connectivity...');

      // Don't check account.get() as it requires authentication
      // Just check if database and collections exist
      final databaseExists = await checkDatabaseExists();

      if (databaseExists) {
        debugPrint('✅ Database and collections exist');
      } else {
        debugPrint('⚠️ Database or collections not found');
        throw Exception(
            'Database not found. Please run the appwrite_setup script to create the database and collections.');
      }
    } catch (e) {
      debugPrint('❌ Error initializing database: $e');
      rethrow;
    }
  }

  // Ensure laptop collection exists
  Future<bool> ensureLaptopCollectionExists() async {
    try {
      debugPrint('Checking if laptops collection exists...');
      debugPrint(
          'Database ID: $databaseId, Collection ID: $laptopsCollectionId');

      try {
        // Try to list documents in laptops collection
        final result = await databases.listDocuments(
          databaseId: databaseId,
          collectionId: laptopsCollectionId,
          queries: [Query.limit(1)],
        );
        debugPrint(
            'Laptops collection exists, found ${result.documents.length} documents');
        debugPrint('Total documents in collection: ${result.total}');
        return true;
      } catch (e) {
        debugPrint('Error checking laptops collection: $e');
        if (e.toString().contains('Database not found')) {
          debugPrint('Database $databaseId does not exist');
        } else if (e.toString().contains('Collection not found')) {
          debugPrint(
              'Collection $laptopsCollectionId does not exist in database $databaseId');
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error in ensureLaptopCollectionExists: $e');
      return false;
    }
  }

  /// Memeriksa apakah database sudah ada
  Future<bool> checkDatabaseExists() async {
    try {
      debugPrint('🔍 Checking database existence...');

      // Try different collections to check database existence
      final collectionsToCheck = [
        guidesCollectionId, // Try guides first (might have public read)
        laptopsCollectionId, // Then laptops
        tasksCollectionId, // Then tasks
        usersCollectionId, // Users last (most likely to need auth)
      ];

      for (String collectionId in collectionsToCheck) {
        try {
          debugPrint('🔍 Trying collection: $collectionId');
          await databases.listDocuments(
            databaseId: databaseId,
            collectionId: collectionId,
            queries: [Query.limit(1)],
          );
          debugPrint(
              '✅ Database exists - confirmed via collection: $collectionId');
          return true;
        } catch (e) {
          debugPrint('⚠️ Error checking $collectionId: $e');

          // If it's a database/project not found error, definitely false
          if (e.toString().contains('database_not_found') ||
              e.toString().contains('Database not found') ||
              e.toString().contains('project_not_found')) {
            debugPrint('❌ Database definitely does not exist');
            return false;
          }

          // If it's a permission/scope error, database might exist but we can't access
          // Try the next collection
          if (e.toString().contains('unauthorized') ||
              e.toString().contains('missing scope') ||
              e.toString().contains('collection_not_found')) {
            debugPrint(
                '🔄 Permission issue with $collectionId, trying next...');
            continue;
          }
        }
      }

      // If we've tried all collections and got permission errors,
      // assume database exists but we don't have proper access yet
      debugPrint('⚠️ Could not confirm database existence due to permissions');
      return false;
    } catch (e) {
      debugPrint('❌ General error checking database: $e');
      return false;
    }
  }

  // Cek apakah user sudah login dan memiliki session aktif
  Future<bool> checkUserSession() async {
    try {
      debugPrint('Checking user session...');
      try {
        final user = await account.get();
        debugPrint('User logged in: ${user.$id}');
        return true;
      } catch (e) {
        debugPrint('No active session: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking user session: $e');
      return false;
    }
  }

  // Authentication methods
  Future<Models.User> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final user = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      // Create user profile in database with error handling
      try {
        // Cek apakah user sudah ada di database
        try {
          final existingUser = await databases.getDocument(
            databaseId: databaseId,
            collectionId: usersCollectionId,
            documentId: user.$id,
          );

          // Jika user sudah ada, tidak perlu membuat lagi
          debugPrint(
              'User profile dengan ID ${user.$id} sudah ada di database');
        } catch (e) {
          // Jika user belum ada (error document_not_found), buat user baru
          debugPrint('Membuat user profile baru untuk ID ${user.$id}');

          await databases.createDocument(
            databaseId: databaseId,
            collectionId: usersCollectionId,
            documentId: user.$id,
            data: {
              'user_id': user.$id,
              'email': email,
              'name': name ?? '',
              'created_at': DateTime.now().toIso8601String(),
              'theme': 'light',
              'notifications_enabled': true,
            },
          );
        }
      } catch (e) {
        debugPrint('Error saat membuat/memeriksa user profile: $e');
        // Tetap lanjutkan karena user Appwrite sudah terbuat
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<Models.Session> login({
    required String email,
    required String password,
  }) async {
    try {
      return await account.createEmailSession(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (e) {
      rethrow;
    }
  }

  Future<Models.User?> getCurrentUser() async {
    try {
      return await account.get();
    } catch (e) {
      return null;
    }
  }

  // User profile methods
  Future<User> getUserProfile(String userId) async {
    try {
      final document = await databases.getDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
      );

      return User.fromJson(document.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<User> updateUserProfile(User user) async {
    try {
      final document = await databases.updateDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: user.id,
        data: user.toJson(),
      );

      return User.fromJson(document.data);
    } catch (e) {
      rethrow;
    }
  }

  // Laptop methods
  Future<Laptop> createLaptop({
    required String userId,
    required String name,
    String? brand,
    String? model,
    DateTime? purchaseDate,
    String? os,
    String? ram,
    String? storage,
    String? cpu,
    String? gpu,
    String? imageId,
  }) async {
    debugPrint('AppwriteService.createLaptop dipanggil');
    debugPrint('userId: $userId, name: $name');
    debugPrint('Database ID: $databaseId, Collection ID: $laptopsCollectionId');

    try {
      // Validasi input data terlebih dahulu
      if (name.trim().isEmpty) {
        throw Exception('Nama laptop tidak boleh kosong');
      }

      // Cek apakah database dan collection sudah ada
      await _ensureDatabaseAndCollectionExist();

      // Coba buat dokumen laptop baru
      final laptopId = const Uuid().v4();
      final now = DateTime.now();
      debugPrint('Membuat laptop dengan ID: $laptopId');

      // Siapkan data dengan validasi
      final Map<String, dynamic> data = {
        'laptop_id': laptopId,
        'user_id': userId,
        'name': name.trim(),
        'brand': (brand ?? '').trim(),
        'model': (model ?? '').trim(),
        'purchase_date': purchaseDate?.toIso8601String() ?? '',
        'os': (os ?? '').trim(),
        'ram': (ram ?? '').trim(),
        'storage': (storage ?? '').trim(),
        'cpu': (cpu ?? '').trim(),
        'gpu': (gpu ?? '').trim(),
        'image_id': imageId ?? '',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      debugPrint('Data yang akan disimpan: $data');

      // Buat dokumen dengan timeout
      final result = await databases.createDocument(
        databaseId: databaseId,
        collectionId: laptopsCollectionId,
        documentId: ID.unique(),
        data: data,
        permissions: [
          Permission.read(Role.any()),
          Permission.write(Role.any()),
          Permission.update(Role.any()),
          Permission.delete(Role.any()),
        ],
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Timeout: Koneksi ke database terlalu lama');
        },
      );

      debugPrint('Dokumen berhasil dibuat dengan ID: ${result.$id}');

      // Buat objek Laptop dari hasil
      return Laptop(
        laptopId: laptopId,
        userId: userId,
        name: name.trim(),
        brand: (brand ?? '').trim(),
        model: (model ?? '').trim(),
        purchaseDate: purchaseDate,
        os: (os ?? '').trim(),
        ram: (ram ?? '').trim(),
        storage: (storage ?? '').trim(),
        cpu: (cpu ?? '').trim(),
        gpu: (gpu ?? '').trim(),
        imageId: imageId,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      debugPrint('Error saat membuat laptop: $e');

      // Provide more specific error messages
      String errorMessage = e.toString();
      if (e.toString().contains('user_unauthorized') ||
          e.toString().contains('Permission denied')) {
        errorMessage =
            'Permission error: Collection laptops belum dikonfigurasi dengan benar. Silakan setup database terlebih dahulu.';
        debugPrint('ERROR PERMISSION: Collection permission tidak sesuai');
      } else if (e.toString().contains('collection_not_found')) {
        errorMessage = 'Collection not found: Koleksi laptops tidak ditemukan';
        debugPrint('ERROR KOLEKSI: Koleksi laptops tidak ditemukan');
      } else if (e.toString().contains('database_not_found')) {
        errorMessage = 'Database not found: Database tidak ditemukan';
        debugPrint('ERROR DATABASE: Database tidak ditemukan');
      } else if (e.toString().contains('project_not_found')) {
        errorMessage = 'Project not found: Project ID tidak valid';
        debugPrint('ERROR PROJECT: Project ID tidak valid');
      } else if (e.toString().contains('Timeout')) {
        errorMessage = 'Timeout: Koneksi ke server terlalu lama';
        debugPrint('ERROR TIMEOUT: Koneksi terlalu lama');
      }

      // Throw dengan pesan error yang lebih jelas
      throw Exception(errorMessage);
    }
  }

  /// Memastikan database dan collection sudah ada
  Future<void> _ensureDatabaseAndCollectionExist() async {
    debugPrint('Memeriksa eksistensi database dan collection...');

    try {
      // Test dengan mencoba list documents
      await databases.listDocuments(
        databaseId: databaseId,
        collectionId: laptopsCollectionId,
        queries: [Query.limit(1)],
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Database check timeout');
        },
      );

      debugPrint('Database dan collection sudah ada');
    } catch (e) {
      debugPrint('Error checking database: $e');

      if (e.toString().contains('database_not_found')) {
        throw Exception(
            'Database belum dibuat. Silakan buat database dengan ID: $databaseId di Appwrite Console atau jalankan setup script.');
      } else if (e.toString().contains('collection_not_found')) {
        throw Exception(
            'Collection laptops belum dibuat. Silakan buat collection dengan ID: $laptopsCollectionId di Appwrite Console atau jalankan setup script.');
      } else if (e.toString().contains('project_not_found')) {
        throw Exception(
            'Project tidak ditemukan. Periksa Project ID: $projectId di constant/appwrite.dart');
      }

      // Untuk error lainnya, re-throw
      rethrow;
    }
  }

  Future<List<Laptop>> getLaptops(String userId) async {
    try {
      final documents = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: laptopsCollectionId,
        queries: [
          Query.equal('user_id', userId),
        ],
      );

      return documents.documents
          .map((doc) => Laptop.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Laptop> getLaptop(String laptopId) async {
    try {
      // Cari document berdasarkan laptop_id karena document ID dan laptop_id berbeda
      final documents = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: laptopsCollectionId,
        queries: [
          Query.equal('laptop_id', laptopId),
        ],
      );

      if (documents.documents.isEmpty) {
        throw Exception('Laptop dengan ID $laptopId tidak ditemukan');
      }

      return Laptop.fromJson(documents.documents.first.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Laptop> updateLaptop(Laptop laptop) async {
    try {
      debugPrint(
          'updateLaptop: Looking for laptop with laptopId: ${laptop.laptopId}');

      // Cari document berdasarkan laptop_id karena document ID dan laptop_id berbeda
      final documents = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: laptopsCollectionId,
        queries: [
          Query.equal('laptop_id', laptop.laptopId),
        ],
      );

      if (documents.documents.isEmpty) {
        throw Exception(
            'Laptop dengan ID ${laptop.laptopId} tidak ditemukan untuk update');
      }

      final documentId = documents.documents.first.$id;
      debugPrint('updateLaptop: Found document with ID: $documentId');

      // Update document menggunakan document ID dari Appwrite
      final document = await databases.updateDocument(
        databaseId: databaseId,
        collectionId: laptopsCollectionId,
        documentId: documentId,
        data: {
          ...laptop.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('updateLaptop: Successfully updated laptop');
      return Laptop.fromJson(document.data);
    } catch (e) {
      debugPrint('updateLaptop: Error - $e');
      rethrow;
    }
  }

  Future<void> deleteLaptop(String laptopId) async {
    try {
      // Cari document berdasarkan laptop_id karena document ID dan laptop_id berbeda
      final documents = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: laptopsCollectionId,
        queries: [
          Query.equal('laptop_id', laptopId),
        ],
      );

      if (documents.documents.isEmpty) {
        throw Exception('Laptop dengan ID $laptopId tidak ditemukan');
      }

      // Hapus document menggunakan document ID dari Appwrite
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: laptopsCollectionId,
        documentId: documents.documents.first.$id,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Maintenance task methods
  Future<MaintenanceTask> createMaintenanceTask({
    required String userId,
    required String laptopId,
    required TaskCategory category,
    required String title,
    required String description,
    required TaskFrequency frequency,
    required TaskPriority priority,
  }) async {
    try {
      final taskId = const Uuid().v4();
      final document = await databases.createDocument(
        databaseId: databaseId,
        collectionId: tasksCollectionId,
        documentId: taskId,
        data: {
          'task_id': taskId,
          'user_id': userId,
          'laptop_id': laptopId,
          'category': category.value,
          'title': title,
          'description': description,
          'frequency': frequency.value,
          'priority': priority.value,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      return MaintenanceTask.fromJson(document.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<MaintenanceTask>> getMaintenanceTasks({
    required String userId,
    String? laptopId,
    TaskCategory? category,
  }) async {
    try {
      List<String> queries = [Query.equal('user_id', userId)];

      if (laptopId != null) {
        queries.add(Query.equal('laptop_id', laptopId));
      }

      if (category != null) {
        queries.add(Query.equal('category', category.value));
      }

      final documents = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: tasksCollectionId,
        queries: queries,
      );

      return documents.documents
          .map((doc) => MaintenanceTask.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<MaintenanceTask> updateMaintenanceTask(MaintenanceTask task) async {
    try {
      final document = await databases.updateDocument(
        databaseId: databaseId,
        collectionId: tasksCollectionId,
        documentId: task.taskId,
        data: {
          ...task.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      return MaintenanceTask.fromJson(document.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMaintenanceTask(String taskId) async {
    try {
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: tasksCollectionId,
        documentId: taskId,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Maintenance history methods
  Future<MaintenanceHistory> recordMaintenanceHistory({
    required String userId,
    required String laptopId,
    required String taskId,
    required DateTime completionDate,
    String? notes,
  }) async {
    try {
      final historyId = const Uuid().v4();
      final document = await databases.createDocument(
        databaseId: databaseId,
        collectionId: historyCollectionId,
        documentId: historyId,
        data: {
          'history_id': historyId,
          'user_id': userId,
          'laptop_id': laptopId,
          'task_id': taskId,
          'completion_date': completionDate.toIso8601String(),
          'notes': notes ?? '',
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      return MaintenanceHistory.fromJson(document.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<MaintenanceHistory>> getMaintenanceHistory({
    required String userId,
    String? laptopId,
    String? taskId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<String> queries = [Query.equal('user_id', userId)];

      if (laptopId != null) {
        queries.add(Query.equal('laptop_id', laptopId));
      }

      if (taskId != null) {
        queries.add(Query.equal('task_id', taskId));
      }

      if (startDate != null) {
        queries.add(Query.greaterThanEqual(
            'completion_date', startDate.toIso8601String()));
      }

      if (endDate != null) {
        queries.add(
            Query.lessThanEqual('completion_date', endDate.toIso8601String()));
      }

      final documents = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: historyCollectionId,
        queries: queries,
      );

      return documents.documents
          .map((doc) => MaintenanceHistory.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Reminder methods
  Future<Reminder> createReminder({
    required String userId,
    required String laptopId,
    required String taskId,
    required DateTime scheduledDate,
    required TaskFrequency frequency,
  }) async {
    try {
      final reminderId = const Uuid().v4();
      final document = await databases.createDocument(
        databaseId: databaseId,
        collectionId: remindersCollectionId,
        documentId: reminderId,
        data: {
          'reminder_id': reminderId,
          'user_id': userId,
          'laptop_id': laptopId,
          'task_id': taskId,
          'scheduled_date': scheduledDate.toIso8601String(),
          'frequency': frequency.value,
          'status': ReminderStatus.pending.value,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      return Reminder.fromJson(document.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Reminder>> getReminders({
    required String userId,
    String? laptopId,
    ReminderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<String> queries = [Query.equal('user_id', userId)];

      if (laptopId != null) {
        queries.add(Query.equal('laptop_id', laptopId));
      }

      if (status != null) {
        queries.add(Query.equal('status', status.value));
      }

      if (startDate != null) {
        queries.add(Query.greaterThanEqual(
            'scheduled_date', startDate.toIso8601String()));
      }

      if (endDate != null) {
        queries.add(
            Query.lessThanEqual('scheduled_date', endDate.toIso8601String()));
      }

      final documents = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: remindersCollectionId,
        queries: queries,
      );

      return documents.documents
          .map((doc) => Reminder.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Reminder> updateReminderStatus({
    required String reminderId,
    required ReminderStatus status,
  }) async {
    try {
      final document = await databases.updateDocument(
        databaseId: databaseId,
        collectionId: remindersCollectionId,
        documentId: reminderId,
        data: {
          'status': status.value,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      return Reminder.fromJson(document.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Reminder> updateReminder({
    required String reminderId,
    required String taskId,
    required DateTime scheduledDate,
    required TaskFrequency frequency,
    required ReminderStatus status,
  }) async {
    try {
      final document = await databases.updateDocument(
        databaseId: databaseId,
        collectionId: remindersCollectionId,
        documentId: reminderId,
        data: {
          'task_id': taskId,
          'scheduled_date': scheduledDate.toIso8601String(),
          'frequency': frequency.value,
          'status': status.value,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      return Reminder.fromJson(document.data);
    } catch (e) {
      rethrow;
    }
  }

  // Guide methods
  Future<List<Guide>> getGuides({
    TaskCategory? category,
    GuideDifficulty? difficulty,
    bool? isPremium,
  }) async {
    try {
      List<String> queries = [];

      if (category != null) {
        queries.add(Query.equal('category', category.value));
      }

      if (difficulty != null) {
        queries.add(Query.equal('difficulty', difficulty.value));
      }

      if (isPremium != null) {
        queries.add(Query.equal('is_premium', isPremium));
      }

      final documents = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: guidesCollectionId,
        queries: queries,
      );

      return documents.documents
          .map((doc) => Guide.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Guide> getGuide(String guideId) async {
    try {
      final document = await databases.getDocument(
        databaseId: databaseId,
        collectionId: guidesCollectionId,
        documentId: guideId,
      );

      return Guide.fromJson(document.data);
    } catch (e) {
      rethrow;
    }
  }

  // Storage methods
  Future<Models.File> uploadImage(Uint8List fileBytes, String fileName) async {
    try {
      return await storage.createFile(
        bucketId: storageId,
        fileId: ID.unique(),
        file: InputFile.fromBytes(
          bytes: fileBytes,
          filename: fileName,
        ),
        permissions: [
          Permission.read(Role.any()),
          Permission.write(Role.any()),
          Permission.update(Role.any()),
          Permission.delete(Role.any()),
        ],
      );
    } catch (e) {
      debugPrint('Error uploading image: $e');

      // Provide user-friendly error messages
      String errorMessage = e.toString();
      if (e.toString().contains('user_unauthorized') ||
          e.toString().contains('401')) {
        errorMessage =
            'Storage permission error: Please setup storage bucket with proper permissions in Appwrite console.';
      } else if (e.toString().contains('bucket_not_found')) {
        errorMessage =
            'Storage bucket not found: Please create storage bucket "$storageId" in Appwrite console.';
      } else if (e.toString().contains('project_not_found')) {
        errorMessage = 'Project not found: Please check project configuration.';
      }

      throw Exception(errorMessage);
    }
  }

  Future<String> getImageUrl(String fileId) async {
    try {
      debugPrint('getImageUrl: Getting URL for fileId: $fileId');

      // Construct the public file view URL manually
      // Format: https://[ENDPOINT]/v1/storage/buckets/[BUCKET_ID]/files/[FILE_ID]/view?project=[PROJECT_ID]
      final url =
          '$endpoint/storage/buckets/$storageId/files/$fileId/view?project=$projectId';

      debugPrint('getImageUrl: Generated URL: $url');
      return url;
    } catch (e) {
      debugPrint('getImageUrl: Error - $e');
      rethrow;
    }
  }

  // User management methods
  Future<Models.User> getAccount() async {
    try {
      return await account.get();
    } catch (e) {
      rethrow;
    }
  }

  Future<User> getUserById(String userId) async {
    try {
      final document = await databases.getDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
      );

      return User.fromJson(document.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Models.Document> createUser({
    required String userId,
    required String email,
    required String name,
  }) async {
    try {
      // Cek apakah user sudah ada di database
      try {
        final existingUser = await databases.getDocument(
          databaseId: databaseId,
          collectionId: usersCollectionId,
          documentId: userId,
        );

        // Jika user sudah ada, kembalikan dokumen yang sudah ada
        debugPrint(
            'User dengan ID $userId sudah ada, mengembalikan dokumen yang sudah ada');
        return existingUser;
      } catch (e) {
        // Jika user belum ada (error document_not_found), buat user baru
        debugPrint('User dengan ID $userId belum ada, membuat user baru');

        return await databases.createDocument(
          databaseId: databaseId,
          collectionId: usersCollectionId,
          documentId: userId,
          data: {
            'user_id': userId,
            'email': email,
            'name': name,
            'created_at': DateTime.now().toIso8601String(),
            'last_login': DateTime.now().toIso8601String(),
            'theme': 'light',
            'notifications_enabled': true,
          },
        );
      }
    } catch (e) {
      debugPrint('Error saat membuat/mendapatkan user: $e');
      rethrow;
    }
  }

  Future<Models.Document> updateUser({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Coba update dokumen tanpa permissions
      return await databases.updateDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
        data: data,
      );
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }
}
