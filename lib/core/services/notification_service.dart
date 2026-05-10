import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

enum NotificationPermissionState { unknown, granted, denied, unsupported }

NotificationPermissionState permissionStateFromEnabled(bool? enabled) {
  return switch (enabled) {
    true => NotificationPermissionState.granted,
    false => NotificationPermissionState.denied,
    null => NotificationPermissionState.unknown,
  };
}

bool isManagedNotificationPayload(String? payload) {
  return payload?.startsWith('subscription:') == true ||
      payload?.startsWith('archive:') == true ||
      payload?.startsWith('test:') == true;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'subscription_reminders';
  static const _channelName = 'Subscription reminders';
  static const _channelDescription = 'Reminders before subscription payments';
  static const _archiveChannelId = 'subscription_archive_timers';
  static const _archiveChannelName = 'Subscription archive timers';
  static const _archiveChannelDescription =
      'Notifications for automatic subscription archive timers';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  NotificationPermissionState _lastPermissionState =
      NotificationPermissionState.unknown;
  Future<void> Function(String payload)? _onPayload;

  Future<void> initialize({
    Future<void> Function(String payload)? onPayload,
  }) async {
    if (onPayload != null) {
      _onPayload = onPayload;
    }
    if (_initialized) return;

    tz_data.initializeTimeZones();
    _setLocalLocation('Europe/Moscow');

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    _initialized = true;

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    final payload = response?.payload;
    if (launchDetails?.didNotificationLaunchApp == true &&
        payload != null &&
        payload.isNotEmpty) {
      _dispatchPayload(payload);
    }
  }

  Future<NotificationPermissionState> getPermissionState() async {
    await initialize();

    if (kIsWeb) return NotificationPermissionState.unsupported;

    if (Platform.isAndroid) {
      final implementation = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (implementation == null) {
        return NotificationPermissionState.unsupported;
      }
      final state = permissionStateFromEnabled(
        await implementation.areNotificationsEnabled(),
      );
      _lastPermissionState = state;
      return state;
    }

    if (Platform.isIOS) {
      final implementation = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (implementation == null) {
        return NotificationPermissionState.unsupported;
      }
      final state = permissionStateFromEnabled(
        (await implementation.checkPermissions())?.isEnabled,
      );
      _lastPermissionState = state;
      return state;
    }

    if (Platform.isMacOS) {
      final implementation = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (implementation == null) {
        return NotificationPermissionState.unsupported;
      }
      final state = permissionStateFromEnabled(
        (await implementation.checkPermissions())?.isEnabled,
      );
      _lastPermissionState = state;
      return state;
    }

    return NotificationPermissionState.unsupported;
  }

  Future<NotificationPermissionState> requestPermissions() async {
    await initialize();

    if (kIsWeb) {
      _lastPermissionState = NotificationPermissionState.unsupported;
      return _lastPermissionState;
    }

    bool? granted;
    if (Platform.isAndroid) {
      final implementation = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (implementation == null) {
        _lastPermissionState = NotificationPermissionState.unsupported;
        return _lastPermissionState;
      }
      granted = await implementation.requestNotificationsPermission();
      granted ??= await implementation.areNotificationsEnabled();
    } else if (Platform.isIOS) {
      final implementation = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (implementation == null) {
        _lastPermissionState = NotificationPermissionState.unsupported;
        return _lastPermissionState;
      }
      granted = await implementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isMacOS) {
      final implementation = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (implementation == null) {
        _lastPermissionState = NotificationPermissionState.unsupported;
        return _lastPermissionState;
      }
      granted = await implementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else {
      _lastPermissionState = NotificationPermissionState.unsupported;
      return _lastPermissionState;
    }

    _lastPermissionState = permissionStateFromEnabled(granted);
    return _lastPermissionState;
  }

  Future<void> requestPermissionsIfNeeded() async {
    if (_lastPermissionState == NotificationPermissionState.granted) return;
    await requestPermissions();
  }

  Future<void> cancelAllSubscriptionReminders() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    final reminderIds = pending
        .where(
            (request) => request.payload?.startsWith('subscription:') ?? false)
        .map((request) => request.id);

    for (final id in reminderIds) {
      await _plugin.cancel(id);
    }
  }

  Future<void> cancelAllManagedNotifications() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (isManagedNotificationPayload(request.payload)) {
        await _plugin.cancel(request.id);
      }
    }
  }

  Future<NotificationPermissionState> showTestNotification() async {
    final permissionState = await requestPermissions();
    if (permissionState != NotificationPermissionState.granted) {
      return permissionState;
    }

    await _plugin.show(
      900001,
      'Тестовое уведомление',
      'SubsFlow может присылать локальные напоминания.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      payload: 'test:notification',
    );
    return permissionState;
  }

  Future<void> scheduleSubscriptionReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String timezone,
    required String payload,
  }) async {
    await initialize();
    _setLocalLocation(timezone);

    final localScheduledAt = tz.TZDateTime.from(scheduledAt, tz.local);
    if (!localScheduledAt.isAfter(tz.TZDateTime.now(tz.local))) {
      return;
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      localScheduledAt,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleArchiveTimerNotification({
    required int id,
    required String subscriptionName,
    required DateTime scheduledAt,
    required String timezone,
  }) async {
    await requestPermissionsIfNeeded();
    _setLocalLocation(timezone);

    final localScheduledAt = tz.TZDateTime.from(scheduledAt, tz.local);
    if (!localScheduledAt.isAfter(tz.TZDateTime.now(tz.local))) {
      return;
    }

    await _plugin.zonedSchedule(
      id,
      'Archive timer',
      '$subscriptionName will be moved to archive.',
      localScheduledAt,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _archiveChannelId,
          _archiveChannelName,
          channelDescription: _archiveChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'archive:$id',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelArchiveTimerNotification(int id) async {
    await initialize();
    await _plugin.cancel(id);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    _dispatchPayload(payload);
  }

  void _dispatchPayload(String payload) {
    final callback = _onPayload;
    if (callback == null) return;
    unawaited(callback(payload));
  }

  void _setLocalLocation(String timezone) {
    try {
      tz.setLocalLocation(tz.getLocation(timezone));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Moscow'));
    }
  }
}
