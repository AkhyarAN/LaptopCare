import 'package:flutter/material.dart';
import '../data/services/appwrite_service.dart';

class AppwriteInitializer {
  static final AppwriteService _appwriteService = AppwriteService();

  static Future<void> initialize(BuildContext context) async {
    try {
      debugPrint('🚀 Memulai inisialisasi Appwrite...');
      await _appwriteService.init();
      debugPrint('✅ Appwrite SDK berhasil diinisialisasi');

      // Check if database exists (without requiring authentication)
      try {
        debugPrint('🔍 Memeriksa keberadaan database...');

        // Check database exists by trying to access a collection
        // This won't require authentication if permissions are set correctly
        final databaseExists = await _appwriteService.checkDatabaseExists();

        if (databaseExists) {
          debugPrint('✅ Database dan collections tersedia');
        } else {
          debugPrint('⚠️ Database belum tersedia');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Database belum dikonfigurasi. Silakan setup melalui Profile.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (dbError) {
        debugPrint('⚠️ Error saat memeriksa database: $dbError');

        // Check if it's a permission issue (which is normal before login)
        if (dbError.toString().contains('general_unauthorized_scope') ||
            dbError.toString().contains('missing scope') ||
            dbError.toString().contains('unauthorized')) {
          debugPrint('🔒 Permission issue - this is normal before login');
          // Don't show any error to the user, this is expected
        } else {
          // Other database issues - show a warning but don't block app startup
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Peringatan database: ${_getSimpleErrorMessage(dbError.toString())}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      debugPrint('✅ Inisialisasi Appwrite selesai');
    } catch (e) {
      debugPrint('❌ Error fatal saat inisialisasi Appwrite: $e');

      // Handle permission errors gracefully
      if (e.toString().contains('general_unauthorized_scope') ||
          e.toString().contains('missing scope') ||
          e.toString().contains('unauthorized')) {
        debugPrint('🔒 Permission issue - this is normal before login');
        // Don't show any error to the user, this is expected
        return;
      }

      // Don't show blocking dialog - just log error and continue
      debugPrint(
          '⚠️ Melanjutkan tanpa Appwrite - beberapa fitur mungkin tidak tersedia');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Koneksi Appwrite bermasalah: ${_getSimpleErrorMessage(e.toString())}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  /// Convert technical error messages to user-friendly Indonesian messages
  static String _getSimpleErrorMessage(String error) {
    if (error.contains('general_unauthorized_scope') ||
        error.contains('missing scope') ||
        error.contains('unauthorized')) {
      return 'Belum login - ini normal';
    } else if (error.contains('project_not_found')) {
      return 'Project tidak ditemukan';
    } else if (error.contains('database_not_found')) {
      return 'Database belum dikonfigurasi';
    } else if (error.contains('collection_not_found')) {
      return 'Collections belum dibuat';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'Masalah koneksi internet';
    } else if (error.contains('timeout')) {
      return 'Koneksi timeout';
    } else {
      return 'Kesalahan teknis';
    }
  }
}
