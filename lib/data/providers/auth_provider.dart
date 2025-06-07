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

  Future<void> checkAuthStatus() async {
    _setLoading(true);
    try {
      _appwriteUser = await _appwriteService.getCurrentUser();

      if (_appwriteUser != null) {
        _currentUser =
            await _appwriteService.getUserProfile(_appwriteUser!.$id);
      }
    } catch (e) {
      _setError(e.toString());
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
        _error = 'Login gagal: ${e.toString()}';
        debugPrint(_error);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Terjadi kesalahan: ${e.toString()}';
      debugPrint(_error);
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
      _error = e.toString();
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
      _currentUser = null;
      _appwriteUser = null;
    } catch (e) {
      _error = e.toString();
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
      _error = e.toString();
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
