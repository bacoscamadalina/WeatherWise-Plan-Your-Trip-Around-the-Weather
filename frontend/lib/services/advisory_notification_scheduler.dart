import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'advisory_notification_planner.dart';

abstract interface class AdvisoryNotificationScheduler {
  bool get isSupported;

  Future<bool> requestPermission();

  Future<void> replaceAll(List<PlannedAdvisoryNotification> notifications);

  Future<void> cancelAll();
}

class UnsupportedAdvisoryNotificationScheduler
    implements AdvisoryNotificationScheduler {
  const UnsupportedAdvisoryNotificationScheduler();

  @override
  bool get isSupported => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> replaceAll(
    List<PlannedAdvisoryNotification> notifications,
  ) async {}

  @override
  Future<void> cancelAll() async {}
}

class LocalAdvisoryNotificationScheduler
    implements AdvisoryNotificationScheduler {
  LocalAdvisoryNotificationScheduler({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialization;

  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    await _initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, sound: true) ??
        false;
  }

  @override
  Future<void> replaceAll(
    List<PlannedAdvisoryNotification> notifications,
  ) async {
    if (!isSupported) return;
    await _initialize();
    await _plugin.cancelAll();

    for (final notification in notifications) {
      final value = notification.scheduledAt;
      final scheduledDate = tz.TZDateTime(
        tz.local,
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
      );
      if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) continue;

      await _plugin.zonedSchedule(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'weatherwise_planning_advisories',
            'Forecast planning reminders',
            channelDescription:
                'Optional reminders for weather conditions that may affect a plan.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(
            threadIdentifier: 'weatherwise_planning_advisories',
          ),
          macOS: DarwinNotificationDetails(
            threadIdentifier: 'weatherwise_planning_advisories',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: notification.payload,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!isSupported) return;
    await _initialize();
    await _plugin.cancelAll();
  }

  Future<void> _initialize() => _initialization ??= _initializeOnce();

  Future<void> _initializeOnce() async {
    tz_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_weatherwise'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }
}
