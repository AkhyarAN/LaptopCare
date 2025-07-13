import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/appwrite_service.dart';
import '../models/laptop.dart';

class LaptopProvider with ChangeNotifier {
  final AppwriteService _appwriteService = AppwriteService();

  bool _isLoading = false;
  String? _error;
  List<Laptop> _laptops = [];
  Laptop? _selectedLaptop;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Laptop> get laptops => _laptops;
  Laptop? get selectedLaptop => _selectedLaptop;

  Future<void> fetchLaptops(String userId) async {
    // Prevent multiple concurrent fetches
    if (_isLoading) {
      debugPrint('LaptopProvider.fetchLaptops: Already loading, skipping');
      return;
    }

    debugPrint('LaptopProvider.fetchLaptops: Loading data for user $userId');
    _setLoading(true);
    _clearError();

    try {
      _laptops = await _appwriteService.getLaptops(userId);
      debugPrint(
          'LaptopProvider.fetchLaptops: Loaded ${_laptops.length} laptops');

      if (_laptops.isNotEmpty && _selectedLaptop == null) {
        _selectedLaptop = _laptops.first;
      }
    } catch (e) {
      debugPrint('LaptopProvider.fetchLaptops: Error - $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createLaptop({
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
    debugPrint('LaptopProvider.createLaptop dipanggil');
    debugPrint('userId: $userId, name: $name');

    // Set loading state
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      debugPrint('Mencoba membuat laptop baru...');

      // Add timeout untuk mencegah hanging
      final laptop = await _appwriteService
          .createLaptop(
        userId: userId,
        name: name,
        brand: brand,
        model: model,
        purchaseDate: purchaseDate,
        os: os,
        ram: ram,
        storage: storage,
        cpu: cpu,
        gpu: gpu,
        imageId: imageId,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Timeout: Proses menyimpan laptop terlalu lama. Periksa koneksi internet.');
        },
      );

      debugPrint('Berhasil membuat laptop: ${laptop.laptopId}');

      // Update the list
      _laptops.add(laptop);
      _selectedLaptop = laptop;

      debugPrint('Laptop berhasil ditambahkan ke list');
      return true;
    } catch (e) {
      debugPrint('Error membuat laptop: $e');
      _error = e.toString();
      return false;
    } finally {
      // Pastikan loading state selalu di-reset
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateLaptop(Laptop laptop) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedLaptop = await _appwriteService.updateLaptop(laptop);

      final index = _laptops.indexWhere((l) => l.laptopId == laptop.laptopId);
      if (index != -1) {
        _laptops[index] = updatedLaptop;
      }

      if (_selectedLaptop?.laptopId == laptop.laptopId) {
        _selectedLaptop = updatedLaptop;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteLaptop(String laptopId) async {
    _setLoading(true);
    _clearError();

    try {
      await _appwriteService.deleteLaptop(laptopId);

      _laptops.removeWhere((laptop) => laptop.laptopId == laptopId);

      if (_selectedLaptop?.laptopId == laptopId) {
        _selectedLaptop = _laptops.isNotEmpty ? _laptops.first : null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void selectLaptop(String laptopId) {
    final laptop = _laptops.firstWhere(
      (laptop) => laptop.laptopId == laptopId,
      orElse: () => _laptops.first,
    );

    _selectedLaptop = laptop;
    notifyListeners();
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

  /// Clear semua data laptop (untuk logout atau ganti user)
  void clearData() {
    debugPrint('LaptopProvider.clearData: Membersihkan semua data laptop');

    // Only notify if there's actually data to clear
    final hasData = _laptops.isNotEmpty ||
        _selectedLaptop != null ||
        _error != null ||
        _isLoading;

    _laptops.clear();
    _selectedLaptop = null;
    _error = null;
    _isLoading = false;

    if (hasData) {
      notifyListeners();
    }
  }
}
