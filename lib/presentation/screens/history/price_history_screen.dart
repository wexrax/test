import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../providers/subscription_provider.dart';

class PriceHistoryScreen extends ConsumerWidget {
  const PriceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(subscriptionPriceHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('История изменения цен')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Не удалось загрузить историю цен'),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Изменений цен пока нет',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final delta = item.newAmount - item.oldAmount;
              final isIncrease = delta > 0;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  child: Icon(
                    isIncrease
                        ? Icons.trending_up
                        : delta < 0
                            ? Icons.trending_down
                            : Icons.remove,
                  ),
                ),
                title: Text(item.subscriptionTitle),
                subtitle: Text(item.changedAt.dayMonth),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.oldAmount.rub} -> ${item.newAmount.rub}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      delta == 0
                          ? '0 ₽'
                          : '${isIncrease ? '+' : ''}${delta.rub}',
                      style: TextStyle(
                        color: isIncrease
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
