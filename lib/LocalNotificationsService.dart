import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

class LocalNotificationsService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Initialize notifications
  static Future<void> initialize() async {
    // Initialize timezone data FIRST
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Johannesburg')); // Use specific location instead of tz.local

    // Android settings
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    final DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings settings =
    InitializationSettings(android: androidSettings, iOS: iosSettings);

    // Initialize plugin
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
      },
    );

    // Request exact alarm permissions on Android
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final bool canScheduleExact = await androidPlugin?.canScheduleExactNotifications() ?? false;

      if (!canScheduleExact) {
        print('Requesting exact alarm permission...');
        await androidPlugin?.requestExactAlarmsPermission();
      }
    }
  }

  // Check if exact alarms are permitted (Android 14+)
  static Future<bool> canScheduleExactNotifications() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.canScheduleExactNotifications() ?? false;
    }
    return true;
  }

  // Request exact alarm permission (Android 14+)
  static Future<bool> requestExactAlarmsPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.requestExactAlarmsPermission() ?? false;
    }
    return true;
  }

  // Show immediate notification
  static Future<void> showNotification(String title, String body,
      {String? payload}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'event_channel', // Changed to more specific channel
      'Event Notifications',
      channelDescription: 'Notifications for scheduled events',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(0, title, body, details, payload: payload);
  }

  // Schedule a notification
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
  }) async {

    // Debug prints
    print('Scheduling notification for: $scheduledTime');
    print('Current time: ${tz.TZDateTime.now(tz.local)}');
    print('Time difference: ${scheduledTime.difference(tz.TZDateTime.now(tz.local)).inMinutes} minutes');

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'event_channel', // Same channel as immediate notifications
      'Event Notifications',
      channelDescription: 'Notifications for scheduled events',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      ticker: 'Event Reminder',
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    // Check if we can schedule exact alarms
    bool canScheduleExact = await canScheduleExactNotifications();
    AndroidScheduleMode scheduleMode = canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    print('Using schedule mode: $scheduleMode');
    print('Can schedule exact: $canScheduleExact');

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      print('Notification scheduled successfully with ID: $id');

      // Verify the notification was scheduled
      final pendingNotifications = await _notificationsPlugin.pendingNotificationRequests();
      print('Pending notifications: ${pendingNotifications.length}');
      for (var notification in pendingNotifications) {
        print('- ID: ${notification.id}, Title: ${notification.title}');
      }

    } catch (e) {
      print('Error scheduling notification: $e');

      // Fallback: try with a shorter delay for testing
      final testTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: 10));
      print('Trying fallback notification in 10 seconds...');

      await _notificationsPlugin.zonedSchedule(
        id + 10000, // Different ID for test
        "TEST: $title",
        "Fallback: $body",
        testTime,
        details,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  // Get all pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}