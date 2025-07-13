import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'guide_seeder.dart';
import '../data/services/appwrite_service.dart';

/// A utility class for initializing the Flutter application.
///
/// This class ensures Flutter bindings are initialized and sets the device
/// orientation for mobile platforms.
class AppInitializer {
  /// Initializes the application setup.
  ///
  /// Ensures Flutter bindings are initialized, sets up window dimensions,
  /// configures device orientation settings, and seeds guides if needed.
  static Future<void> initialize() async {
    try {
      _ensureInitialized();
      await _setupDeviceOrientation();
      await _setupGuidesIfNeeded();
      debugPrint(
          '✅ AppInitializer: All initialization steps completed successfully');
    } catch (e) {
      debugPrint('❌ AppInitializer: Error during initialization: $e');
      // Don't rethrow - let the app continue with limited functionality
    }
  }

  /// Ensures that Flutter bindings are initialized.
  static void _ensureInitialized() {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('✅ AppInitializer: Flutter bindings initialized');
    } catch (e) {
      debugPrint('❌ AppInitializer: Error initializing Flutter bindings: $e');
      rethrow;
    }
  }

  /// Configures the device orientation and system UI overlays.
  ///
  /// Locks the device orientation to portrait mode and ensures system
  /// UI overlays are manually configured.
  static Future<void> _setupDeviceOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
      );
      debugPrint(
          '✅ AppInitializer: Device orientation and UI overlays configured');
    } catch (e) {
      debugPrint('❌ AppInitializer: Error setting up device orientation: $e');
      // Don't rethrow - this isn't critical
    }
  }

  /// Check if guides collection exists (don't auto-seed)
  ///
  /// Auto-seeding is now handled through ProfileScreen auto-setup
  static Future<void> _setupGuidesIfNeeded() async {
    try {
      debugPrint('AppInitializer: Checking if guides collection exists...');

      final appwriteService = AppwriteService();

      // Check if guides collection exists
      try {
        final response = await appwriteService.databases.listDocuments(
          databaseId: AppwriteService.databaseId,
          collectionId: AppwriteService.guidesCollectionId,
        );

        debugPrint(
            'AppInitializer: Guides collection accessible with ${response.documents.length} documents');
      } catch (e) {
        // Handle permission errors gracefully
        if (e.toString().contains('general_unauthorized_scope') ||
            e.toString().contains('missing scope') ||
            e.toString().contains('unauthorized')) {
          debugPrint('AppInitializer: Not authenticated yet - this is normal');
        } else {
          debugPrint(
              'AppInitializer: Guides collection not accessible yet: $e');
        }
        debugPrint('AppInitializer: User can use Auto Setup in ProfileScreen');
      }
    } catch (e) {
      debugPrint('AppInitializer: Error checking guides: $e');
      // Don't throw error - app should still work without guides
    }
  }
}
