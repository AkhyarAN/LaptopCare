import 'package:flutter/foundation.dart';
import '../services/appwrite_service.dart';
import '../models/maintenance_task.dart';
import '../models/maintenance_history.dart';

class TaskProvider with ChangeNotifier {
  final AppwriteService _appwriteService = AppwriteService();

  bool _isLoading = false;
  String? _error;
  List<MaintenanceTask> _tasks = [];
  List<MaintenanceHistory> _history = [];
  TaskCategory? _selectedCategory;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MaintenanceTask> get tasks => _tasks;
  List<MaintenanceHistory> get history => _history;
  TaskCategory? get selectedCategory => _selectedCategory;

  List<MaintenanceTask> getTasksByCategory(TaskCategory category) {
    return _tasks.where((task) => task.category == category).toList();
  }

  Future<void> fetchTasks({
    required String userId,
    String? laptopId,
    TaskCategory? category,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _tasks = await _appwriteService.getMaintenanceTasks(
        userId: userId,
        laptopId: laptopId,
        category: category,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createTask({
    required String userId,
    required String laptopId,
    required TaskCategory category,
    required String title,
    required String description,
    required TaskFrequency frequency,
    required TaskPriority priority,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final task = await _appwriteService.createMaintenanceTask(
        userId: userId,
        laptopId: laptopId,
        category: category,
        title: title,
        description: description,
        frequency: frequency,
        priority: priority,
      );

      _tasks.add(task);
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateTask(MaintenanceTask task) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedTask = await _appwriteService.updateMaintenanceTask(task);

      final index = _tasks.indexWhere((t) => t.taskId == task.taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
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

  Future<bool> deleteTask(String taskId) async {
    _setLoading(true);
    _clearError();

    try {
      await _appwriteService.deleteMaintenanceTask(taskId);

      _tasks.removeWhere((task) => task.taskId == taskId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> completeTask({
    required String userId,
    required String laptopId,
    required String taskId,
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('TaskProvider.completeTask: Starting task completion...');
      debugPrint(
          'TaskProvider.completeTask: userId=$userId, laptopId=$laptopId, taskId=$taskId');

      final history = await _appwriteService.recordMaintenanceHistory(
        userId: userId,
        laptopId: laptopId,
        taskId: taskId,
        completionDate: DateTime.now(),
        notes: notes,
      );

      _history.add(history);
      debugPrint(
          'TaskProvider.completeTask: Maintenance history recorded successfully with ID: ${history.historyId}');
      debugPrint(
          'TaskProvider.completeTask: Total history records: ${_history.length}');
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('TaskProvider.completeTask: ERROR - $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTaskHistory({
    required String userId,
    String? laptopId,
    String? taskId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _history = await _appwriteService.getMaintenanceHistory(
        userId: userId,
        laptopId: laptopId,
        taskId: taskId,
        startDate: startDate,
        endDate: endDate,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleTaskCompletion(MaintenanceTask task) async {
    _setLoading(true);
    _clearError();

    try {
      // Create history record for task completion
      final history = await _appwriteService.recordMaintenanceHistory(
        userId: task.userId,
        laptopId: task.laptopId,
        taskId: task.taskId,
        completionDate: DateTime.now(),
        notes: "Task marked as completed",
      );

      _history.add(history);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void setSelectedCategory(TaskCategory? category) {
    _selectedCategory = category;
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

  /// Clear semua data task (untuk logout atau ganti user)
  void clearData() {
    debugPrint('TaskProvider.clearData: Membersihkan semua data task');

    // Only notify if there's actually data to clear
    final hasData = _tasks.isNotEmpty ||
        _history.isNotEmpty ||
        _selectedCategory != null ||
        _error != null ||
        _isLoading;

    _tasks.clear();
    _history.clear();
    _selectedCategory = null;
    _error = null;
    _isLoading = false;

    if (hasData) {
      notifyListeners();
    }
  }

  Future<void> loadTasks(String userId,
      {String? laptopId, TaskCategory? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _appwriteService.getMaintenanceTasks(
        userId: userId,
        laptopId: laptopId,
        category: category,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
