// lib/presentation/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/export_utils.dart';
import '../../../core/widgets/quick_action_button.dart';
import '../../../core/widgets/subscription_list_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../../core/utils/date_utils.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final monthlyCost = ref.watch(monthlyCostProvider);
    final count = ref.watch(activeSubscriptionsProvider).length;
    final yearly = ref.watch(yearlyCostProvider);
    final avgCheck = ref.watch(averageCheckProvider);
    final nextPayment = ref.watch(nextPaymentDateProvider);
    final wallet = ref.watch(walletNotifierProvider);
    final upcoming = ref.watch(upcomingSubscriptionsProvider(4));
    final categories = ref.watch(categoryBreakdownProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: SingleChildScrollView(
        // Убираем горизонтальные отступы, оставляем только вертикальные
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Карточка трат в месяц – растянута на всю ширину
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.monthlySpending,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Text(
                      '${monthlyCost.rub} / мес.',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'vs рынок 2500 ₽',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _infoChip(context, Icons.subscriptions,
                            l10n.subscriptionCount(count.toString())),
                        _infoChip(context, Icons.calendar_today,
                            l10n.yearlySpending(yearly.rub)),
                        _infoChip(context, Icons.receipt_long,
                            l10n.averageCheck(avgCheck.rub)),
                        _infoChip(context, Icons.timer,
                            l10n.nextPayment(nextPayment?.dayMonth ?? '—')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Кошелёк – кликабельный, ведёт на /wallet
            InkWell(
              onTap: () => context.push('/wallet'),
              borderRadius: BorderRadius.circular(AppDimens.radiusExtraLarge),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet,
                          color: AppColors.walletBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.walletBalance(wallet.balance.rub),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              l10n.walletSufficientFor(
                                monthlyCost > 0
                                    ? (wallet.balance / monthlyCost).floor()
                                    : 0,
                              ),
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Быстрые действия
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.quickActions,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  QuickActionButton(
                    icon: Icons.add_circle,
                    label: l10n.addSubscription,
                    onTap: () => context.push('/add-subscription'),
                  ),
                  QuickActionButton(
                    icon: Icons.calendar_month,
                    label: l10n.calendar,
                    onTap: () => context.push('/calendar'),
                  ),
                  QuickActionButton(
                    icon: Icons.history,
                    label: l10n.history,
                    onTap: () => context.push('/history'),
                  ),
                  QuickActionButton(
                    icon: Icons.download,
                    label: l10n.export,
                    onTap: () async {
                      final csv = ref.read(subscriptionsCsvProvider);
                      await shareCsvFile(csv, 'subscriptions.csv');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Ближайшие списания
            if (upcoming.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n.upcomingPayments,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              ...upcoming.map((sub) => SubscriptionListTile(
                subscription: sub,
                onTap: () =>
                    context.push('/subscriptions/${sub.id}'),
              )),
            ],

            // По категориям
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n.categories,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              ...categories.entries.map((entry) {
                final percent = monthlyCost > 0
                    ? (entry.value / monthlyCost * 100).clamp(0, 100)
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Text(entry.value.rub),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(AppDimens.radiusSmall),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          minHeight: 6,
                          backgroundColor:
                          AppColors.primary.withValues(alpha: 0.2),
                          valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurface),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}