import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Kelas utilitas untuk menangani error pada aplikasi Flutter
class ErrorHandler {
  /// Inisialisasi error handler untuk mengatasi masalah mouse tracker
  static void initialize() {
    // Mengabaikan error mouse tracker yang umum terjadi di Windows
    FlutterError.onError = (FlutterErrorDetails details) {
      final exception = details.exception.toString().toLowerCase();

      // Abaikan error yang umum terjadi di Windows
      if (exception.contains('mousetracker') ||
          exception.contains('mouse_tracker') ||
          exception.contains('cannot hit test') ||
          exception.contains('render box with no size') ||
          exception.contains('setstate') ||
          exception.contains('markNeedsBuild') ||
          details.library?.contains('mouse_tracker.dart') == true ||
          details.library?.contains('object.dart') == true) {
        // Hanya log error untuk debugging
        if (kDebugMode) {
          print('Error diabaikan: ${details.summary}');
        }
        return;
      }

      // Untuk error lainnya, gunakan handler default
      FlutterError.presentError(details);
    };

    // Nonaktifkan debugPaintSizeEnabled untuk mencegah masalah render
    debugPaintSizeEnabled = false;
  }
}
