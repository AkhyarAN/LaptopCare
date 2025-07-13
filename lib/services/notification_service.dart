import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../data/models/maintenance_task.dart';
import '../data/models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Set local timezone
    final String timeZoneName = await _getLocalTimeZone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    debugPrint('NotificationService: Timezone set to $timeZoneName');

    // Android settings with more aggressive configuration
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('NotificationService: Initialized successfully');
  }

  Future<String> _getLocalTimeZone() async {
    try {
      // Default untuk Indonesia
      return 'Asia/Jakarta';
    } catch (e) {
      debugPrint('Error getting timezone: $e');
      return 'Asia/Jakarta'; // Fallback
    }
  }

  Future<bool> requestPermissions() async {
    debugPrint('NotificationService: Requesting permissions...');

    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Request basic notification permission
      final bool? granted =
          await androidImplementation?.requestNotificationsPermission();

      // For Android 12+ request exact alarm permission
      final bool? exactAlarmGranted =
          await androidImplementation?.requestExactAlarmsPermission();

      debugPrint('NotificationService: Basic permission: $granted');
      debugPrint(
          'NotificationService: Exact alarm permission: $exactAlarmGranted');

      return (granted ?? false) && (exactAlarmGranted ?? true);
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      final bool? granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('NotificationService: iOS permission: $granted');
      return granted ?? false;
    }

    return true; // For other platforms, assume permission granted
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('Notification tapped with payload: $payload');
      // Handle notification tap - navigate to specific task or reminder
      // This can be expanded to handle navigation
    }
  }

  Future<void> scheduleMaintenanceReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required TaskFrequency frequency,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    // Validate scheduled date
    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) {
      debugPrint(
          'NotificationService: WARNING - Scheduled date is in the past: $scheduledDate');
      // Schedule for tomorrow instead
      final tomorrow = DateTime(now.year, now.month, now.day + 1,
          scheduledDate.hour, scheduledDate.minute);
      return await scheduleMaintenanceReminder(
        id: id,
        title: title,
        body: body,
        scheduledDate: tomorrow,
        frequency: frequency,
        payload: payload,
      );
    }

    // Convert to timezone-aware DateTime
    final tz.TZDateTime tzDateTime =
        tz.TZDateTime.from(scheduledDate, tz.local);

    debugPrint('NotificationService: Scheduling notification');
    debugPrint('  - ID: $id');
    debugPrint('  - Title: $title');
    debugPrint('  - Body: $body');
    debugPrint('  - Original DateTime: $scheduledDate');
    debugPrint('  - TZ DateTime: $tzDateTime');
    debugPrint('  - Current Time: ${tz.TZDateTime.now(tz.local)}');

    // Enhanced Android notification details for better delivery
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'maintenance_reminders',
      'Maintenance Reminders',
      channelDescription: 'Notifications for laptop maintenance tasks',
      importance: Importance.max, // Changed to max for better delivery
      priority: Priority.max, // Changed to max for better delivery
      showWhen: true,
      when: null,
      usesChronometer: false,
      icon: '@mipmap/ic_launcher',
      // Add these for better midnight delivery
      enableVibration: true,
      enableLights: true,
      ledOnMs: 1000,
      ledOffMs: 500,
      // Critical for Android battery optimization
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      // Wake up the device
      fullScreenIntent: false,
      // Audio attributes for better delivery
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      interruptionLevel: InterruptionLevel.timeSensitive, // Better for midnight
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notificationDetails,
        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle, // Critical for midnight
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents:
            DateTimeComponents.dateAndTime, // Ensure exact time match
      );

      debugPrint(
          'NotificationService: Successfully scheduled notification for $tzDateTime');

      // Log all pending notifications for debugging
      await _logPendingNotifications();
    } catch (e) {
      debugPrint('NotificationService: Error scheduling notification: $e');
      rethrow;
    }

    // Schedule recurring notifications based on frequency
    await _scheduleRecurringNotification(
      id: id,
      title: title,
      body: body,
      initialDate: tzDateTime,
      frequency: frequency,
      payload: payload,
    );
  }

  Future<void> _logPendingNotifications() async {
    try {
      final pendingNotifications =
          await _notifications.pendingNotificationRequests();
      debugPrint(
          'NotificationService: Pending notifications count: ${pendingNotifications.length}');

      for (final notification in pendingNotifications) {
        debugPrint(
            '  - ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}');
      }
    } catch (e) {
      debugPrint(
          'NotificationService: Error getting pending notifications: $e');
    }
  }

  Future<void> _scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime initialDate,
    required TaskFrequency frequency,
    String? payload,
  }) async {
    // Enhanced Android notification details for recurring notifications
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'maintenance_reminders',
      'Maintenance Reminders',
      channelDescription: 'Notifications for laptop maintenance tasks',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      enableLights: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    switch (frequency) {
      case TaskFrequency.daily:
        // Schedule next 7 days individually for better reliability
        for (int i = 1; i <= 7; i++) {
          final nextDate = tz.TZDateTime(
            tz.local,
            initialDate.year,
            initialDate.month,
            initialDate.day + i,
            initialDate.hour,
            initialDate.minute,
          );

          await _notifications.zonedSchedule(
            id + (i * 10000), // Unique ID pattern
            title,
            body,
            nextDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: payload,
            matchDateTimeComponents: DateTimeComponents.dateAndTime,
          );
        }
        break;

      case TaskFrequency.weekly:
        // Schedule next 4 weeks individually
        for (int i = 1; i <= 4; i++) {
          final nextDate = tz.TZDateTime(
            tz.local,
            initialDate.year,
            initialDate.month,
            initialDate.day + (i * 7),
            initialDate.hour,
            initialDate.minute,
          );

          await _notifications.zonedSchedule(
            id + (i * 20000), // Unique ID pattern
            title,
            body,
            nextDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: payload,
            matchDateTimeComponents: DateTimeComponents.dateAndTime,
          );
        }
        break;

      case TaskFrequency.monthly:
        // Schedule next 3 months individually
        for (int i = 1; i <= 3; i++) {
          final nextDate = tz.TZDateTime(
            tz.local,
            initialDate.year,
            initialDate.month + i,
            initialDate.day,
            initialDate.hour,
            initialDate.minute,
          );

          await _notifications.zonedSchedule(
            id + (i * 30000), // Unique ID pattern
            title,
            body,
            nextDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: payload,
            matchDateTimeComponents: DateTimeComponents.dateAndTime,
          );
        }
        break;

      case TaskFrequency.quarterly:
        // Schedule next 2 quarters individually
        for (int i = 1; i <= 2; i++) {
          final quarterlyDate = tz.TZDateTime(
            tz.local,
            initialDate.year,
            initialDate.month + (i * 3),
            initialDate.day,
            initialDate.hour,
            initialDate.minute,
          );

          await _notifications.zonedSchedule(
            id + (i * 40000), // Unique ID pattern
            title,
            body,
            quarterlyDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: payload,
            matchDateTimeComponents: DateTimeComponents.dateAndTime,
          );
        }
        break;
    }

    debugPrint(
        'NotificationService: Scheduled recurring notifications for frequency: ${frequency.value}');
  }

  Future<void> cancelNotification(int id) async {
    // Cancel main notification
    await _notifications.cancel(id);

    // Cancel all possible recurring notifications with different ID patterns
    for (int i = 1; i <= 10; i++) {
      await _notifications.cancel(id + (i * 10000)); // Daily
      await _notifications.cancel(id + (i * 20000)); // Weekly
      await _notifications.cancel(id + (i * 30000)); // Monthly
      await _notifications.cancel(id + (i * 40000)); // Quarterly
    }

    debugPrint(
        'NotificationService: Cancelled notification with ID: $id and all recurring instances');
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('NotificationService: Cancelled all notifications');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'instant_notifications',
      'Instant Notifications',
      channelDescription: 'Immediate notifications for important updates',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      enableLights: true,
      visibility: NotificationVisibility.public,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    debugPrint('NotificationService: Showed instant notification - $title');
  }

  // Helper method to generate unique notification ID
  int generateNotificationId(String reminderId) {
    return reminderId.hashCode.abs();
  }

  // Schedule notification for maintenance task reminder
  Future<void> scheduleTaskReminder({
    required Reminder reminder,
    required MaintenanceTask task,
    required String laptopName,
  }) async {
    final notificationId = generateNotificationId(reminder.reminderId);

    debugPrint('NotificationService: Scheduling task reminder');
    debugPrint('  - Reminder ID: ${reminder.reminderId}');
    debugPrint('  - Notification ID: $notificationId');
    debugPrint('  - Task: ${task.title}');
    debugPrint('  - Laptop: $laptopName');
    debugPrint('  - Scheduled for: ${reminder.scheduledDate}');

    await scheduleMaintenanceReminder(
      id: notificationId,
      title: '🔧 Maintenance Reminder: ${task.title}',
      body:
          'Time to perform "${task.title}" on $laptopName. Don\'t forget to take care of your laptop!',
      scheduledDate: reminder.scheduledDate,
      frequency: reminder.frequency,
      payload: 'reminder:${reminder.reminderId}:task:${task.taskId}',
    );
  }

  // Cancel specific task reminder
  Future<void> cancelTaskReminder(String reminderId) async {
    final notificationId = generateNotificationId(reminderId);
    debugPrint(
        'NotificationService: Cancelling task reminder - $reminderId (ID: $notificationId)');
    await cancelNotification(notificationId);
  }

  // Debug method to check notification status
  Future<Map<String, dynamic>> getNotificationDebugInfo() async {
    final pendingNotifications = await getPendingNotifications();
    final now = DateTime.now();
    final currentTZ = tz.TZDateTime.now(tz.local);

    final debugInfo = {
      'isInitialized': _isInitialized,
      'pendingNotificationsCount': pendingNotifications.length,
      'currentDateTime': now.toString(),
      'currentTimeZone': currentTZ.timeZoneName,
      'pendingNotifications': pendingNotifications
          .map((n) => {
                'id': n.id,
                'title': n.title,
                'body': n.body,
              })
          .toList(),
    };

    debugPrint('NotificationService Debug Info: $debugInfo');
    return debugInfo;
  }

  // Method to test notification immediately
  Future<void> testNotificationNow() async {
    await showInstantNotification(
      id: 99999,
      title: '🧪 Test Notification',
      body:
          'This is a test notification to verify the notification system is working properly.',
      payload: 'test_notification',
    );
  }
}
 