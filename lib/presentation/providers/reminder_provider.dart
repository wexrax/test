import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final subscriptionRemindersProvider =
    Provider<List<SubscriptionReminderData>>((ref) {
  final settings = ref.watch(settingsProvider);
  final subscriptions = ref.watch(activeSubscriptionsProvider);
  final enabledDays = <int>{
    if (settings['notify_7days'] == 'true') 7,
    if (settings['notify_3days'] == 'true') 3,
    if (settings['notify_1day'] == 'true') 1,
  };

  if (enabledDays.isEmpty) {
    return const [];
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final reminders = <SubscriptionReminderData>[];

  for (final subscription in subscriptions) {
    final paymentDay = DateTime(
      subscription.nextPaymentDate.year,
      subscription.nextPaymentDate.month,
      subscription.nextPaymentDate.day,
    );
    final daysUntilPayment = paymentDay.difference(today).inDays;

    if (!enabledDays.contains(daysUntilPayment)) {
      continue;
    }

    reminders.add(
      SubscriptionReminderData(
        subscription: subscription,
        daysUntilPayment: daysUntilPayment,
        remindAt: today,
      ),
    );
  }

  reminders.sort(
    (a, b) => a.subscription.nextPaymentDate.compareTo(
      b.subscription.nextPaymentDate,
    ),
  );
  return reminders;
});
