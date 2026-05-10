import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../data/local/app_database.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> archiveDueSubscriptionsAlarmCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  await AppDatabase.instance.archiveDueSubscriptions(DateTime.now());
  await AppDatabase.instance.cancelDueTrials(DateTime.now());
  await AppDatabase.instance.close();
}

class ArchiveTimerService {
  ArchiveTimerService._();

  static final ArchiveTimerService instance = ArchiveTimerService._();

  static const _alarmIdBase = 700000;
  static const _notificationIdBase = 800000;

  bool _initialized = false;
  final Map<int, Timer> _timers = {};

  Future<void> initialize() async {
    if (_initialized) return;

    if (_isAndroid) {
      await AndroidAlarmManager.initialize();
    }

    _initialized = true;
  }

  Future<void> reconcileDue() async {
    final now = DateTime.now();
    await Future.wait([
      AppDatabase.instance.archiveDueSubscriptions(now),
      AppDatabase.instance.cancelDueTrials(now),
    ]);
  }

  Future<void> schedule({
    required int subscriptionId,
    required String subscriptionName,
    required DateTime archiveAt,
    required String timezone,
    Future<void> Function()? onDue,
  }) async {
    await initialize();
    await cancel(subscriptionId);

    if (!archiveAt.isAfter(DateTime.now())) {
      await reconcileDue();
      return;
    }

    _timers[subscriptionId] = Timer(archiveAt.difference(DateTime.now()), () {
      _timers.remove(subscriptionId);
      Future<void>(() async {
        await reconcileDue();
        await onDue?.call();
      });
    });

    await NotificationService.instance.scheduleArchiveTimerNotification(
      id: _notificationId(subscriptionId),
      subscriptionName: subscriptionName,
      scheduledAt: archiveAt,
      timezone: timezone,
    );

    if (_isAndroid) {
      await _scheduleAndroidAlarm(subscriptionId, archiveAt, exact: true);
    }
  }

  Future<void> cancel(int subscriptionId) async {
    await initialize();
    _timers.remove(subscriptionId)?.cancel();
    await NotificationService.instance.cancelArchiveTimerNotification(
      _notificationId(subscriptionId),
    );

    if (_isAndroid) {
      await AndroidAlarmManager.cancel(_alarmId(subscriptionId));
    }
  }

  Future<void> _scheduleAndroidAlarm(
    int subscriptionId,
    DateTime archiveAt, {
    required bool exact,
  }) async {
    try {
      await AndroidAlarmManager.oneShotAt(
        archiveAt,
        _alarmId(subscriptionId),
        archiveDueSubscriptionsAlarmCallback,
        exact: exact,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
    } catch (_) {
      if (exact) {
        await _scheduleAndroidAlarm(subscriptionId, archiveAt, exact: false);
      }
    }
  }

  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  static int _alarmId(int subscriptionId) => _alarmIdBase + subscriptionId;

  static int _notificationId(int subscriptionId) {
    return _notificationIdBase + subscriptionId;
  }
}
