import 'package:flutter/foundation.dart';
import '../services/appwrite_service.dart';
import '../models/reminder.dart';
import '../models/maintenance_task.dart';
import '../../services/notification_service.dart';

class ReminderProvider with ChangeNotifier {
  final AppwriteService _appwriteService = AppwriteService();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = false;
  String? _error;
  List<Reminder> _reminders = [];
  bool _isNotificationInitialized = false;

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

      // Re-schedule notifications for pending reminders
      await _rescheduleExistingReminders();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _rescheduleExistingReminders() async {
    try {
      debugPrint(
          'ReminderProvider: Re-scheduling ${_reminders.length} existing reminders');

      for (final reminder in _reminders) {
        // Only reschedule pending reminders that are in the future
        if (reminder.status == ReminderStatus.pending &&
            reminder.scheduledDate.isAfter(DateTime.now())) {
          await _scheduleReminderNotification(
              reminder, reminder.taskId, reminder.laptopId);
        }
      }

      debugPrint(
          'ReminderProvider: Completed re-scheduling existing reminders');
    } catch (e) {
      debugPrint(
          'ReminderProvider: Error re-scheduling existing reminders: $e');
      // Don't fail the fetch if re-scheduling fails
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
      debugPrint('=== ReminderProvider.createReminder START ===');
      debugPrint('  - userId: $userId');
      debugPrint('  - laptopId: $laptopId');
      debugPrint('  - taskId: $taskId');
      debugPrint('  - scheduledDate: $scheduledDate');
      debugPrint('  - frequency: ${frequency.value}');

      // Create reminder in database
      final reminder = await _appwriteService.createReminder(
        userId: userId,
        laptopId: laptopId,
        taskId: taskId,
        scheduledDate: scheduledDate,
        frequency: frequency,
      );

      debugPrint('  - Database save successful: ${reminder.reminderId}');
      _reminders.add(reminder);

      // Schedule notification immediately after creating reminder
      debugPrint('  - Starting notification scheduling...');
      await _scheduleReminderNotification(reminder, taskId, laptopId);

      debugPrint('=== ReminderProvider.createReminder SUCCESS ===');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('=== ReminderProvider.createReminder ERROR ===');
      debugPrint('Error creating reminder: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _ensureNotificationInitialized() async {
    if (!_isNotificationInitialized) {
      try {
        debugPrint('      - Starting notification initialization...');
        await _notificationService.initialize();
        debugPrint('      - NotificationService.initialize() completed');

        final hasPermission = await _notificationService.requestPermissions();
        debugPrint('      - Permission request result: $hasPermission');

        if (hasPermission) {
          _isNotificationInitialized = true;
          debugPrint('      - Notification service fully initialized ✅');
        } else {
          debugPrint('      - Notification permission denied ❌');
        }
      } catch (e) {
        debugPrint('      - Error initializing notification service: $e');
      }
    } else {
      debugPrint('      - Notification service already initialized ✅');
    }
  }

  Future<void> _scheduleReminderNotification(
      Reminder reminder, String taskId, String laptopId) async {
    try {
      debugPrint('  === _scheduleReminderNotification START ===');
      debugPrint('    - Reminder ID: ${reminder.reminderId}');
      debugPrint('    - Scheduled for: ${reminder.scheduledDate}');
      debugPrint('    - Task ID: $taskId');
      debugPrint('    - Laptop ID: $laptopId');

      // Ensure notification service is initialized
      debugPrint('    - Initializing notification service...');
      await _ensureNotificationInitialized();
      debugPrint(
          '    - Notification service initialized: $_isNotificationInitialized');

      // Fetch task details
      debugPrint('    - Fetching task details...');
      final tasks = await _appwriteService.getMaintenanceTasks(
        userId: reminder.userId,
        laptopId: laptopId,
      );
      debugPrint('    - Found ${tasks.length} tasks');

      final task = tasks.firstWhere(
        (t) => t.taskId == taskId,
        orElse: () => throw Exception('Task not found with ID: $taskId'),
      );
      debugPrint('    - Task found: ${task.title}');

      // Fetch laptop details
      debugPrint('    - Fetching laptop details...');
      final laptops = await _appwriteService.getLaptops(reminder.userId);
      debugPrint('    - Found ${laptops.length} laptops');

      final laptop = laptops.firstWhere(
        (l) => l.laptopId == laptopId,
        orElse: () => throw Exception('Laptop not found with ID: $laptopId'),
      );
      debugPrint('    - Laptop found: ${laptop.name}');

      // Schedule the notification
      debugPrint('    - Calling NotificationService.scheduleTaskReminder...');
      await _notificationService.scheduleTaskReminder(
        reminder: reminder,
        task: task,
        laptopName: laptop.name,
      );

      debugPrint('  === _scheduleReminderNotification SUCCESS ===');
      debugPrint('    - Notification scheduled for: ${reminder.scheduledDate}');

      // Debug: Check pending notifications
      final debugInfo = await _notificationService.getNotificationDebugInfo();
      debugPrint(
          '    - Total pending notifications: ${debugInfo['pendingNotificationsCount']}');
    } catch (e) {
      debugPrint('  === _scheduleReminderNotification ERROR ===');
      debugPrint('    - Error: $e');
      debugPrint('    - Stack trace: ${StackTrace.current}');
      // Don't fail the reminder creation if notification scheduling fails
      // The reminder is still valid, just without automatic notification
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
    final success = await updateReminderStatus(
      reminderId: reminderId,
      status: ReminderStatus.completed,
    );

    // Cancel notification when marked as completed
    if (success) {
      try {
        await _notificationService.cancelTaskReminder(reminderId);
        debugPrint(
            'ReminderProvider: Cancelled notification for completed reminder $reminderId');
      } catch (e) {
        debugPrint('ReminderProvider: Error cancelling notification: $e');
      }
    }

    return success;
  }

  Future<bool> markReminderAsSent(String reminderId) async {
    return await updateReminderStatus(
      reminderId: reminderId,
      status: ReminderStatus.sent,
    );
  }

  Future<bool> updateReminder({
    required String reminderId,
    required String taskId,
    required DateTime scheduledDate,
    required TaskFrequency frequency,
    required ReminderStatus status,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedReminder = await _appwriteService.updateReminder(
        reminderId: reminderId,
        taskId: taskId,
        scheduledDate: scheduledDate,
        frequency: frequency,
        status: status,
      );

      final index = _reminders.indexWhere((r) => r.reminderId == reminderId);
      if (index != -1) {
        _reminders[index] = updatedReminder;
      }

      // Update notification scheduling
      await _updateReminderNotification(updatedReminder);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating reminder: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _updateReminderNotification(Reminder updatedReminder) async {
    try {
      debugPrint(
          'ReminderProvider: Updating notification for reminder ${updatedReminder.reminderId}');

      // Cancel old notification first
      await _notificationService.cancelTaskReminder(updatedReminder.reminderId);

      // If status is still pending, reschedule notification
      if (updatedReminder.status == ReminderStatus.pending) {
        await _scheduleReminderNotification(
            updatedReminder, updatedReminder.taskId, updatedReminder.laptopId);
      }

      debugPrint('ReminderProvider: Successfully updated notification');
    } catch (e) {
      debugPrint('ReminderProvider: Error updating notification: $e');
      // Don't fail the reminder update if notification update fails
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

  /// Clear semua data reminder (untuk logout atau ganti user)
  void clearData() {
    debugPrint('ReminderProvider.clearData: Membersihkan semua data reminder');

    // Only notify if there's actually data to clear
    final hasData = _reminders.isNotEmpty || _error != null || _isLoading;

    _reminders.clear();
    _error = null;
    _isLoading = false;

    if (hasData) {
      notifyListeners();
    }
  }

  // Debug methods untuk troubleshooting notification
  Future<void> debugNotificationStatus() async {
    // Simplified debug method - just log basic info
    debugPrint('ReminderProvider: Notification system check');
    debugPrint('  - Reminder count: ${_reminders.length}');
    debugPrint(
        '  - Notification service initialized: $_isNotificationInitialized');
  }

  // Test notification immediately
  Future<bool> testNotificationNow() async {
    // Simplified test method
    try {
      await _ensureNotificationInitialized();
      if (_isNotificationInitialized) {
        await _notificationService.testNotificationNow();
        debugPrint('Test notification sent successfully');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending test notification: $e');
      return false;
    }
  }
}
