// lib/presentation/providers/reminder_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import 'settings_provider.dart';
import 'subscription_provider.dart';

class SubscriptionReminderData {
  const SubscriptionReminderData({
    required this.subscription,
    required this.daysUntilPayment,
    required this.remindAt,
  });

  final SubscriptionData subscription;
  final int daysUntilPayment;
  final DateTime remindAt;
}

class NotificationScheduleSummary {
  const NotificationScheduleSummary({
    required this.enabled,
    required this.scheduledCount,
    required this.enabledDays,
    required this.timezone,
  });

  final bool enabled;
  final int scheduledCount;
  final Set<int> enabledDays;
  final String timezone;
}

class NotificationActions {
  const NotificationActions(this._ref, this._notifications);

  final Ref _ref;
  final NotificationService _notifications;

  Future<NotificationPermissionState> requestPermissions() {
    return _notifications.requestPermissions();
  }

  Future<NotificationPermissionState> showTestNotification() {
    return _notifications.showTestNotification();
  }

  Future<void> resyncSchedule() {
    return _SubscriptionReminderScheduler(_ref, _notifications).reschedule();
  }
}

final subscriptionRemindersProvider =
    Provider<List<SubscriptionReminderData>>((ref) {
  return buildSubscriptionReminders(
    settings: ref.watch(settingsProvider),
    subscriptions: ref.watch(activeSubscriptionsProvider),
  );
});

final notificationScheduleSummaryProvider =
    Provider<NotificationScheduleSummary>((ref) {
  final settings = ref.watch(settingsProvider);
  final subscriptions = ref.watch(activeSubscriptionsProvider);
  final enabledDays = enabledReminderDays(settings);

  return NotificationScheduleSummary(
    enabled: enabledDays.isNotEmpty,
    scheduledCount: countScheduledSubscriptionReminders(
      settings: settings,
      subscriptions: subscriptions,
    ),
    enabledDays: enabledDays,
    timezone: settings['timezone'] ?? 'Europe/Moscow',
  );
});

final notificationPermissionProvider =
    FutureProvider.autoDispose<NotificationPermissionState>((ref) {
  return ref.watch(notificationServiceProvider).getPermissionState();
});

final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref, ref.watch(notificationServiceProvider));
});

List<SubscriptionReminderData> buildSubscriptionReminders({
  required Map<String, String> settings,
  required Iterable<SubscriptionData> subscriptions,
  DateTime? now,
}) {
  final enabledDays = enabledReminderDays(settings);
  if (enabledDays.isEmpty) return const [];

  final effectiveNow = now ?? DateTime.now();
  final today =
      DateTime(effectiveNow.year, effectiveNow.month, effectiveNow.day);
  final reminders = <SubscriptionReminderData>[];

  for (final subscription in subscriptions) {
    if (!subscription.isVisibleActive) continue;

    final paymentDay = DateTime(
      subscription.nextPaymentDate.year,
      subscription.nextPaymentDate.month,
      subscription.nextPaymentDate.day,
    );
    final daysUntilPayment = paymentDay.difference(today).inDays;
    if (!enabledDays.contains(daysUntilPayment)) continue;

    reminders.add(
      SubscriptionReminderData(
        subscription: subscription,
        daysUntilPayment: daysUntilPayment,
        remindAt: today,
      ),
    );
  }

  reminders.sort((a, b) =>
      a.subscription.nextPaymentDate.compareTo(b.subscription.nextPaymentDate));
  return reminders;
}

Set<int> enabledReminderDays(Map<String, String> settings) {
  return {
    if (settings['notify_7days'] == 'true') 7,
    if (settings['notify_3days'] == 'true') 3,
    if (settings['notify_1day'] == 'true') 1,
  };
}

int countScheduledSubscriptionReminders({
  required Map<String, String> settings,
  required Iterable<SubscriptionData> subscriptions,
  DateTime? now,
}) {
  final enabledDays = enabledReminderDays(settings);
  if (enabledDays.isEmpty) return 0;

  final effectiveNow = now ?? DateTime.now();
  var count = 0;
  for (final subscription in subscriptions) {
    if (!subscription.isVisibleActive) continue;
    for (final daysBefore in enabledDays) {
      final scheduledAt =
          scheduledSubscriptionReminderTime(subscription, daysBefore);
      if (scheduledAt.isAfter(effectiveNow)) {
        count++;
      }
    }
  }
  return count;
}

DateTime scheduledSubscriptionReminderTime(
  SubscriptionData subscription,
  int daysBefore,
) {
  final scheduledDay = subscription.nextPaymentDate.subtract(
    Duration(days: daysBefore),
  );
  return DateTime(
    scheduledDay.year,
    scheduledDay.month,
    scheduledDay.day,
    9,
  );
}

int subscriptionReminderNotificationId(int subscriptionId, int daysBefore) {
  return subscriptionId * 10 + daysBefore;
}

String subscriptionReminderBody(String subscriptionName, int daysBefore) {
  if (daysBefore == 1) {
    return 'Завтра списание по подписке $subscriptionName.';
  }
  return 'Через $daysBefore дня списание по подписке $subscriptionName.';
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

final subscriptionReminderSyncProvider = Provider<void>((ref) {
  final scheduler = _SubscriptionReminderScheduler(
    ref,
    ref.watch(notificationServiceProvider),
  );

  ref.listen(settingsProvider, (_, __) => scheduler.reschedule());
  ref.listen(subscriptionNotifierProvider, (_, __) => scheduler.reschedule());

  Future.microtask(scheduler.reschedule);
});

class _SubscriptionReminderScheduler {
  const _SubscriptionReminderScheduler(this._ref, this._notifications);

  final Ref _ref;
  final NotificationService _notifications;

  Future<void> reschedule() async {
    final settings = _ref.read(settingsProvider);
    final subscriptions = _ref.read(activeSubscriptionsProvider);
    final enabledDays = enabledReminderDays(settings);

    await _notifications.cancelAllSubscriptionReminders();
    if (enabledDays.isEmpty || subscriptions.isEmpty) {
      return;
    }

    final permissionState = await _notifications.getPermissionState();
    if (permissionState != NotificationPermissionState.granted) {
      return;
    }

    final timezone = settings['timezone'] ?? 'Europe/Moscow';
    for (final subscription in subscriptions) {
      if (!subscription.isVisibleActive) continue;
      for (final daysBefore in enabledDays) {
        await _notifications.scheduleSubscriptionReminder(
          id: subscriptionReminderNotificationId(
            subscription.id,
            daysBefore,
          ),
          title: 'Скоро списание',
          body: subscriptionReminderBody(subscription.name, daysBefore),
          scheduledAt: scheduledSubscriptionReminderTime(
            subscription,
            daysBefore,
          ),
          timezone: timezone,
          payload: 'subscription:${subscription.id}',
        );
      }
    }
  }
}
