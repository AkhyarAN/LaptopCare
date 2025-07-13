import 'package:flutter/foundation.dart';
import '../models/maintenance_history.dart';
import '../models/maintenance_task.dart';
import '../models/laptop.dart';
import '../services/appwrite_service.dart';

class HistoryProvider with ChangeNotifier {
  final AppwriteService _appwriteService = AppwriteService();

  List<MaintenanceHistory> _history = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedLaptopId;
  DateTime? _startDate;
  DateTime? _endDate;

  List<MaintenanceHistory> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedLaptopId => _selectedLaptopId;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  List<MaintenanceHistory> get filteredHistory {
    List<MaintenanceHistory> filtered = _history;

    if (_selectedLaptopId != null) {
      filtered =
          filtered.where((h) => h.laptopId == _selectedLaptopId).toList();
    }

    if (_startDate != null) {
      filtered = filtered
          .where((h) => h.completionDate
              .isAfter(_startDate!.subtract(const Duration(days: 1))))
          .toList();
    }

    if (_endDate != null) {
      filtered = filtered
          .where((h) =>
              h.completionDate.isBefore(_endDate!.add(const Duration(days: 1))))
          .toList();
    }

    // Sort by completion date descending (newest first)
    filtered.sort((a, b) => b.completionDate.compareTo(a.completionDate));

    return filtered;
  }

  // Statistics calculations
  int get totalMaintenanceCount => _history.length;

  int get thisMonthMaintenanceCount {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _history.where((h) => h.completionDate.isAfter(startOfMonth)).length;
  }

  int get thisWeekMaintenanceCount {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekMidnight =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return _history
        .where((h) => h.completionDate.isAfter(startOfWeekMidnight))
        .length;
  }

  Map<String, int> get maintenanceByLaptop {
    Map<String, int> counts = {};
    for (var h in _history) {
      counts[h.laptopId] = (counts[h.laptopId] ?? 0) + 1;
    }
    return counts;
  }

  Map<DateTime, int> get maintenanceByDate {
    Map<DateTime, int> counts = {};
    for (var h in _history) {
      final date = DateTime(
          h.completionDate.year, h.completionDate.month, h.completionDate.day);
      counts[date] = (counts[date] ?? 0) + 1;
    }
    return counts;
  }

  List<MaintenanceHistory> getRecentHistory({int limit = 10}) {
    final sorted = List<MaintenanceHistory>.from(_history);
    sorted.sort((a, b) => b.completionDate.compareTo(a.completionDate));
    return sorted.take(limit).toList();
  }

  Future<void> fetchHistory(String userId) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('HistoryProvider: Fetching history for user $userId...');
      debugPrint(
          'HistoryProvider: Filters - laptopId: $_selectedLaptopId, startDate: $_startDate, endDate: $_endDate');

      _history = await _appwriteService.getMaintenanceHistory(
        userId: userId,
        laptopId: _selectedLaptopId,
        startDate: _startDate,
        endDate: _endDate,
      );

      debugPrint('HistoryProvider: Fetched ${_history.length} history records');
      debugPrint('HistoryProvider: Statistics calculated:');
      debugPrint('  - Total maintenance: $totalMaintenanceCount');
      debugPrint('  - This month: $thisMonthMaintenanceCount');
      debugPrint('  - This week: $thisWeekMaintenanceCount');
      debugPrint('  - Laptops with maintenance: ${maintenanceByLaptop.length}');

      if (_history.isNotEmpty) {
        debugPrint('HistoryProvider: Recent history sample:');
        for (int i = 0; i < (_history.length > 3 ? 3 : _history.length); i++) {
          final h = _history[i];
          debugPrint(
              '  - ${h.completionDate}: Task ${h.taskId} for Laptop ${h.laptopId}');
        }
      }
    } catch (e) {
      debugPrint('HistoryProvider: Error fetching history - $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recordMaintenance({
    required String userId,
    required String laptopId,
    required String taskId,
    required DateTime completionDate,
    String? notes,
  }) async {
    try {
      debugPrint('HistoryProvider: Recording maintenance...');
      final record = await _appwriteService.recordMaintenanceHistory(
        userId: userId,
        laptopId: laptopId,
        taskId: taskId,
        completionDate: completionDate,
        notes: notes,
      );

      _history.add(record);
      notifyListeners();
      debugPrint('HistoryProvider: Maintenance recorded successfully');
    } catch (e) {
      debugPrint('HistoryProvider: Error recording maintenance - $e');
      throw e;
    }
  }

  void setFilter({
    String? laptopId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _selectedLaptopId = laptopId;
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();
  }

  void clearFilters() {
    _selectedLaptopId = null;
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  void clearData() {
    _history.clear();
    _isLoading = false;
    _error = null;
    _selectedLaptopId = null;
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }
}
