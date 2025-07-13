import 'package:flutter/foundation.dart';
import 'package:appwrite/models.dart' as Models;
import '../services/appwrite_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final AppwriteService _appwriteService = AppwriteService();

  bool _isLoading = false;
  String? _error;
  User? _currentUser;
  Models.User? _appwriteUser;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _currentUser;
  Models.User? get appwriteUser => _appwriteUser;
  bool get isLoggedIn => _appwriteUser != null;

  /// Convert technical errors to user-friendly Indonesian messages
  String _parseAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Credential errors
    if (errorString.contains('user_invalid_credentials') ||
        errorString.contains('invalid credentials')) {
      return 'Email atau password tidak cocok. Silakan periksa kembali.';
    }

    // Registration errors
    if (errorString.contains('user_email_already_exists') ||
        errorString.contains('email already exists')) {
      return 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
    }

    // Password errors
    if (errorString.contains('user_password_mismatch') ||
        errorString.contains('password mismatch')) {
      return 'Password yang dimasukkan salah.';
    }

    if (errorString.contains('password_policy_violation') ||
        errorString.contains('password too weak') ||
        errorString.contains('weak password')) {
      return 'Password terlalu lemah. Gunakan minimal 8 karakter dengan kombinasi huruf, angka, dan simbol.';
    }

    // Email errors
    if (errorString.contains('user_email_not_whitelisted') ||
        errorString.contains('email not found') ||
        errorString.contains('user not found')) {
      return 'Email tidak ditemukan. Silakan daftar terlebih dahulu.';
    }

    if (errorString.contains('invalid_email') ||
        errorString.contains('email invalid') ||
        errorString.contains('malformed email')) {
      return 'Format email tidak valid. Contoh: nama@domain.com';
    }

    // Rate limiting
    if (errorString.contains('rate limit') ||
        errorString.contains('too many requests') ||
        errorString.contains('429')) {
      return 'Terlalu banyak percobaan. Silakan coba lagi dalam beberapa menit.';
    }

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('unreachable')) {
      return 'Koneksi internet bermasalah. Silakan periksa koneksi Anda.';
    }

    // Session errors
    if (errorString.contains('session_already_exists') ||
        errorString.contains('session exists')) {
      return 'Sesi masih aktif. Silakan coba login lagi.';
    }

    if (errorString.contains('session_invalid') ||
        errorString.contains('invalid session') ||
        errorString.contains('session expired')) {
      return 'Sesi telah berakhir. Silakan login kembali.';
    }

    // Specific password policy errors
    if (errorString.contains('password_recently_used')) {
      return 'Password baru tidak boleh sama dengan password sebelumnya.';
    }

    if (errorString.contains('password_personal_data')) {
      return 'Password tidak boleh mengandung informasi pribadi.';
    }

    if (errorString.contains('password_history')) {
      return 'Password sudah pernah digunakan sebelumnya.';
    }

    // Server errors
    if (errorString.contains('500') || errorString.contains('server error')) {
      return 'Server sedang bermasalah. Silakan coba lagi nanti.';
    }

    if (errorString.contains('503') ||
        errorString.contains('service unavailable')) {
      return 'Layanan sedang dalam pemeliharaan. Silakan coba lagi nanti.';
    }

    // Default fallback for unknown errors
    return 'Terjadi kesalahan. Silakan coba lagi atau hubungi dukungan.';
  }

  Future<void> checkAuthStatus() async {
    _setLoading(true);
    _error = null; // Clear any previous errors

    try {
      debugPrint('🔍 Checking authentication status...');
      _appwriteUser = await _appwriteService.getCurrentUser();

      if (_appwriteUser != null) {
        debugPrint('✅ User is authenticated: ${_appwriteUser!.$id}');
        try {
          _currentUser =
              await _appwriteService.getUserProfile(_appwriteUser!.$id);
          debugPrint('✅ User profile loaded successfully');
        } catch (profileError) {
          debugPrint('⚠️ Could not load user profile: $profileError');
          // Keep the Appwrite user but clear the profile
          _currentUser = null;
        }
      } else {
        debugPrint('📝 No authenticated user found');
        _currentUser = null;
      }
    } catch (e) {
      debugPrint('🔍 Auth check error: $e');

      // Handle scope/authentication errors gracefully
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('general_unauthorized_scope') ||
          errorString.contains('missing scope') ||
          errorString.contains('unauthorized') ||
          errorString.contains('401')) {
        debugPrint('📝 User not authenticated (this is normal)');
        // Clear user data without setting error
        _appwriteUser = null;
        _currentUser = null;
      } else {
        // Only set error for actual problems (not authentication issues)
        debugPrint('❌ Actual error during auth check: $e');
        _setError(_parseAuthError(e));
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First try to logout any existing session to avoid the "session already exists" error
      try {
        await _appwriteService.logout();
        debugPrint('Logout berhasil sebelum login');
      } catch (e) {
        // Ignore logout errors - it's okay if there was no session to logout from
        debugPrint('Tidak ada sesi aktif untuk logout: $e');
      }

      // Now attempt to login
      try {
        final session = await _appwriteService.login(
          email: email,
          password: password,
        );

        debugPrint('Login berhasil dengan sessionId: ${session.$id}');

        // Get user account
        _appwriteUser = await _appwriteService.getAccount();
        debugPrint('Berhasil mendapatkan akun: ${_appwriteUser!.$id}');

        // Get user from database or create if not exists
        try {
          _currentUser = await _appwriteService.getUserById(_appwriteUser!.$id);
          debugPrint('Berhasil mendapatkan profil pengguna dari database');
        } catch (e) {
          debugPrint('Gagal mendapatkan profil pengguna: $e');
          debugPrint('Mencoba membuat profil pengguna baru...');

          // Create user in database if not exists
          await _appwriteService.createUser(
            userId: _appwriteUser!.$id,
            email: _appwriteUser!.email,
            name: _appwriteUser!.name,
          );

          _currentUser = User(
            id: _appwriteUser!.$id,
            email: _appwriteUser!.email,
            name: _appwriteUser!.name,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );

          debugPrint('Berhasil membuat profil pengguna baru');
        }

        // Update last login
        try {
          await _appwriteService.updateUser(
            userId: _currentUser!.id,
            data: {
              'last_login': DateTime.now().toIso8601String(),
            },
          );
          debugPrint('Berhasil memperbarui waktu login terakhir');
        } catch (e) {
          debugPrint('Gagal memperbarui waktu login terakhir: $e');
          // Continue anyway, this is not critical
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        _error = _parseAuthError(e);
        debugPrint('Login error: ${e.toString()}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _parseAuthError(e);
      debugPrint('Login wrapper error: ${e.toString()}');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First try to logout any existing session to avoid session conflicts
      try {
        await _appwriteService.logout();
      } catch (e) {
        // Ignore logout errors - it's okay if there was no session to logout from
      }

      final result = await _appwriteService.register(
        email: email,
        password: password,
        name: name,
      );

      _appwriteUser = result;

      // Create user in database
      await _appwriteService.createUser(
        userId: result.$id,
        email: email,
        name: name,
      );

      _currentUser = User(
        id: result.$id,
        email: email,
        name: name,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _appwriteService.logout();

      // Clear user data
      final previousUserId = _currentUser?.id;
      _currentUser = null;
      _appwriteUser = null;

      debugPrint('Logout berhasil untuk user: $previousUserId');
    } catch (e) {
      _error = _parseAuthError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? name,
    String? theme,
    bool? notificationsEnabled,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};

      if (name != null) {
        data['name'] = name;
      }

      if (theme != null) {
        data['theme'] = theme;
      }

      if (notificationsEnabled != null) {
        data['notifications_enabled'] = notificationsEnabled;
      }

      await _appwriteService.updateUser(
        userId: _currentUser!.id,
        data: data,
      );

      // Update local user
      _currentUser = User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        name: name ?? _currentUser!.name,
        createdAt: _currentUser!.createdAt,
        lastLogin: _currentUser!.lastLogin,
        theme: theme ?? _currentUser!.theme,
        notificationsEnabled:
            notificationsEnabled ?? _currentUser!.notificationsEnabled,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
