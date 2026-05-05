// lib/presentation/screens/add_subscription/add_subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/subscription_provider.dart';

/// Готовые шаблоны подписок
class _SubscriptionTemplate {
  final String name;
  final String category;
  final double amount;
  final String period; // 'monthly' или 'yearly'

  const _SubscriptionTemplate({
    required this.name,
    required this.category,
    required this.amount,
    required this.period,
  });
}

// Список шаблонов (российские и популярные зарубежные сервисы)
const _templates = [
  // Видео
  _SubscriptionTemplate(name: 'Netflix', category: 'Видео', amount: 799, period: 'monthly'),
  _SubscriptionTemplate(name: 'YouTube Premium', category: 'Видео', amount: 299, period: 'monthly'),
  _SubscriptionTemplate(name: 'Кинопоиск', category: 'Видео', amount: 399, period: 'monthly'),
  _SubscriptionTemplate(name: 'Okko', category: 'Видео', amount: 499, period: 'monthly'),
  _SubscriptionTemplate(name: 'Иви', category: 'Видео', amount: 399, period: 'monthly'),
  _SubscriptionTemplate(name: 'Wink', category: 'Видео', amount: 299, period: 'monthly'),
  // Музыка
  _SubscriptionTemplate(name: 'Spotify', category: 'Музыка', amount: 299, period: 'monthly'),
  _SubscriptionTemplate(name: 'Яндекс Музыка', category: 'Музыка', amount: 229, period: 'monthly'),
  _SubscriptionTemplate(name: 'VK Музыка', category: 'Музыка', amount: 149, period: 'monthly'),
  _SubscriptionTemplate(name: 'Apple Music', category: 'Музыка', amount: 169, period: 'monthly'),
  _SubscriptionTemplate(name: 'СберЗвук', category: 'Музыка', amount: 199, period: 'monthly'),
  // Облако
  _SubscriptionTemplate(name: 'Яндекс Диск', category: 'Облако', amount: 199, period: 'monthly'),
  _SubscriptionTemplate(name: 'Google One', category: 'Облако', amount: 239, period: 'monthly'),
  _SubscriptionTemplate(name: 'iCloud+', category: 'Облако', amount: 149, period: 'monthly'),
  _SubscriptionTemplate(name: 'Dropbox Plus', category: 'Облако', amount: 999, period: 'monthly'),
  _SubscriptionTemplate(name: 'Облако Mail.ru', category: 'Облако', amount: 99, period: 'monthly'),
];

class AddSubscriptionScreen extends ConsumerWidget {
  const AddSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Группируем шаблоны по категориям
    final grouped = <String, List<_SubscriptionTemplate>>{};
    for (final t in _templates) {
      grouped.putIfAbsent(t.category, () => []).add(t);
    }
    final categories = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить подписку'),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (_, index) {
          final category = categories[index];
          final items = grouped[category]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  category,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...items.map((template) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    template.name[0],
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(template.name),
                subtitle: Text(
                  '${template.amount.toStringAsFixed(0)} ₽ / ${template.period == 'monthly' ? 'мес' : 'год'}',
                ),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () async {
                  // Создаём подписку с датой следующего списания через 30 дней
                  final sub = SubscriptionData(
                    id: 0,
                    name: template.name,
                    category: template.category,
                    amount: template.amount,
                    period: template.period,
                    nextPaymentDate: DateTime.now().add(const Duration(days: 30)),
                    isActive: true,
                    iconColor: AppColors.primary.toARGB32(),
                  );
                  await ref.read(subscriptionNotifierProvider.notifier).add(sub);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${template.name} добавлен'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    // Возвращаемся на дашборд
                    context.go('/dashboard');
                  }
                },
              )),
            ],
          );
        },
      ),
    );
  }
}