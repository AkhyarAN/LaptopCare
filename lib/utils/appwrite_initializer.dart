import 'package:flutter/material.dart';
import '../data/services/appwrite_service.dart';

class AppwriteInitializer {
  static final AppwriteService _appwriteService = AppwriteService();

  static Future<void> initialize(BuildContext context) async {
    try {
      debugPrint('Memulai inisialisasi Appwrite...');
      await _appwriteService.init();
      debugPrint('Appwrite SDK berhasil diinisialisasi');

      try {
        await _appwriteService.initializeDatabase();
        debugPrint('Database Appwrite berhasil diinisialisasi');
      } catch (dbError) {
        debugPrint('Error inisialisasi database: $dbError');
        // Tampilkan pesan error tapi lanjutkan proses
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Peringatan: $dbError'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }

      // Coba logout terlebih dahulu untuk membersihkan sesi yang mungkin bermasalah
      try {
        await _appwriteService.logout();
        debugPrint('Berhasil logout dari sesi sebelumnya');
      } catch (e) {
        debugPrint('Tidak ada sesi aktif untuk logout: $e');
      }

      // Check if user is logged in
      try {
        final currentUser = await _appwriteService.getCurrentUser();

        if (currentUser != null) {
          debugPrint('User sudah login: ${currentUser.$id}');
        } else {
          debugPrint('Tidak ada user yang login');
        }
      } catch (userError) {
        debugPrint('Error saat memeriksa status login: $userError');
      }
    } catch (e) {
      debugPrint('Error fatal saat inisialisasi Appwrite: $e');
      // Show error dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Error Inisialisasi Appwrite'),
            content: Text(
              'Terjadi kesalahan saat inisialisasi layanan Appwrite: $e\n\n'
              'Pastikan Anda telah membuat project di konsol Appwrite dengan ID: ${AppwriteService.projectId}\n\n'
              'Pastikan database ${AppwriteService.databaseId} dan collections yang diperlukan telah dibuat di konsol Appwrite.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
 