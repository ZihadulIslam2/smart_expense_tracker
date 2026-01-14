import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for managing local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    print('[NOTIFICATIONS] Service initialized');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('[NOTIFICATIONS] Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return result ?? true;
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'expense_tracker_channel',
      'Expense Tracker',
      channelDescription: 'Notifications for expense tracking reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
    print('[NOTIFICATIONS] Showed notification: $title');
  }

  /// Schedule daily expense reminder
  Future<void> scheduleDailyExpenseReminder({
    required int hour,
    required int minute,
  }) async {
    await _notifications.zonedSchedule(
      1, // Notification ID
      'Don\'t forget to track your expenses!',
      'Add today\'s expenses to stay on top of your finances 💰',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Daily expense tracking reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    print('[NOTIFICATIONS] Scheduled daily reminder at $hour:$minute');
  }

  /// Schedule goal progress notification
  Future<void> scheduleGoalReminder({
    required String goalName,
    required double progress,
  }) async {
    String message;
    if (progress >= 80) {
      message =
          'You\'re ${progress.toStringAsFixed(0)}% close to your $goalName goal! Keep it up! 🎯';
    } else if (progress >= 50) {
      message =
          'Halfway there! You\'ve reached ${progress.toStringAsFixed(0)}% of your $goalName goal 💪';
    } else {
      message =
          'You\'re ${progress.toStringAsFixed(0)}% towards your $goalName goal. Stay focused! 🚀';
    }

    await showNotification(
      id: 2,
      title: 'Goal Progress Update',
      body: message,
      payload: 'goal_progress',
    );
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('[NOTIFICATIONS] Cancelled notification: $id');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('[NOTIFICATIONS] Cancelled all notifications');
  }

  /// Get notification settings from preferences
  Future<Map<String, dynamic>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool('notifications_enabled') ?? true,
      'dailyReminder': prefs.getBool('daily_reminder_enabled') ?? true,
      'goalReminders': prefs.getBool('goal_reminders_enabled') ?? true,
      'reminderHour': prefs.getInt('reminder_hour') ?? 20,
      'reminderMinute': prefs.getInt('reminder_minute') ?? 0,
    };
  }

  /// Save notification settings
  Future<void> saveNotificationSettings({
    bool? enabled,
    bool? dailyReminder,
    bool? goalReminders,
    int? reminderHour,
    int? reminderMinute,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (enabled != null) {
      await prefs.setBool('notifications_enabled', enabled);
    }
    if (dailyReminder != null) {
      await prefs.setBool('daily_reminder_enabled', dailyReminder);
      if (dailyReminder) {
        final settings = await getNotificationSettings();
        await scheduleDailyExpenseReminder(
          hour: settings['reminderHour'],
          minute: settings['reminderMinute'],
        );
      } else {
        await cancelNotification(1);
      }
    }
    if (goalReminders != null) {
      await prefs.setBool('goal_reminders_enabled', goalReminders);
    }
    if (reminderHour != null) {
      await prefs.setInt('reminder_hour', reminderHour);
    }
    if (reminderMinute != null) {
      await prefs.setInt('reminder_minute', reminderMinute);
    }

    print('[NOTIFICATIONS] Settings saved');
  }

  /// Calculate next instance of specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Send budget alert notification
  Future<void> sendBudgetAlert({
    required String category,
    required double percentage,
  }) async {
    await showNotification(
      id: 3,
      title: '⚠️ Budget Alert',
      body:
          'You\'ve used ${percentage.toStringAsFixed(0)}% of your $category budget',
      payload: 'budget_alert',
    );
  }

  /// Send savings milestone notification
  Future<void> sendSavingsMilestone({required double amount}) async {
    await showNotification(
      id: 4,
      title: '🎉 Savings Milestone!',
      body: 'Congratulations! You\'ve saved \$${amount.toStringAsFixed(2)}',
      payload: 'savings_milestone',
    );
  }
}
