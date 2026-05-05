// lib/presentation/screens/calendar/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/subscription_provider.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final active = ref.watch(activeSubscriptionsProvider);
    final grouped = groupBy(
      active,
      (SubscriptionData s) => DateTime(
        s.nextPaymentDate.year,
        s.nextPaymentDate.month,
        s.nextPaymentDate.day,
      ),
    );
    final sortedKeys = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarTitle)),
      body: sortedKeys.isEmpty
          ? const Center(child: Text('Нет предстоящих списаний'))
          : ListView.builder(
              itemCount: sortedKeys.length,
              itemBuilder: (_, index) {
                final date = sortedKeys[index];
                final items = grouped[date]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        _formatDate(date),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppColors.primary),
                      ),
                    ),
                    ...items.map(
                      (s) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _colorForLetter(s.iconLetter),
                          child: Text(s.iconLetter,
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(s.name),
                        subtitle: Text(s.amount.rub),
                        trailing:
                            Text(s.period == 'monthly' ? 'мес' : 'год'),
                      ),
                    ),
                    const Divider(),
                  ],
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    if (date == today) return 'Сегодня';
    if (date == today.add(const Duration(days: 1))) return 'Завтра';
    final days = date.difference(today).inDays;
    return 'Через $days дн. (${date.day} ${monthName(date.month)})';
  }

  Color _colorForLetter(String letter) {
    final code = letter.isNotEmpty ? letter.codeUnitAt(0) : 65;
    const colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.walletBlue,
      AppColors.danger,
      Colors.orange,
    ];
    return colors[code % colors.length];
  }
}