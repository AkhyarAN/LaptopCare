import 'package:flutter/foundation.dart';
import '../services/appwrite_service.dart';
import '../models/reminder.dart';
import '../models/maintenance_task.dart';

class ReminderProvider with ChangeNotifier {
  final AppwriteService _appwriteService = AppwriteService();

  bool _isLoading = false;
  String? _error;
  List<Reminder> _reminders = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Reminder> get reminders => _reminders;

  List<Reminder> getPendingReminders() {
    return _reminders
        .where((reminder) => reminder.status == ReminderStatus.pending)
        .toList();
  }

  List<Reminder> getUpcomingReminders() {
    final now = DateTime.now();
    return _reminders
        .where((reminder) =>
            reminder.status == ReminderStatus.pending &&
            reminder.scheduledDate.isAfter(now))
        .toList();
  }

  List<Reminder> getOverdueReminders() {
    final now = DateTime.now();
    return _reminders
        .where((reminder) =>
            reminder.status == ReminderStatus.pending &&
            reminder.scheduledDate.isBefore(now))
        .toList();
  }

  Future<void> fetchReminders({
    required String userId,
    String? laptopId,
    ReminderStatus? status,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _reminders = await _appwriteService.getReminders(
        userId: userId,
        laptopId: laptopId,
        status: status,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createReminder({
    required String userId,
    required String laptopId,
    required String taskId,
    required DateTime scheduledDate,
    required TaskFrequency frequency,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final reminder = await _appwriteService.createReminder(
        userId: userId,
        laptopId: laptopId,
        taskId: taskId,
        scheduledDate: scheduledDate,
        frequency: frequency,
      );

      _reminders.add(reminder);
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateReminderStatus({
    required String reminderId,
    required ReminderStatus status,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedReminder = await _appwriteService.updateReminderStatus(
        reminderId: reminderId,
        status: status,
      );

      final index = _reminders.indexWhere((r) => r.reminderId == reminderId);
      if (index != -1) {
        _reminders[index] = updatedReminder;
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

  Future<bool> markReminderAsCompleted(String reminderId) async {
    return await updateReminderStatus(
      reminderId: reminderId,
      status: ReminderStatus.completed,
    );
  }

  Future<bool> markReminderAsSent(String reminderId) async {
    return await updateReminderStatus(
      reminderId: reminderId,
      status: ReminderStatus.sent,
    );
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
