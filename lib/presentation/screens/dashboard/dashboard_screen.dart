import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.monthlySpending,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Text('${monthlyCost.rub} / мес.',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                            child: _infoChip(Icons.subscriptions,
                                l10n.subscriptionCount(count.toString()))),
                        const SizedBox(width: 12),
                        Flexible(
                            child: _infoChip(Icons.calendar_today,
                                l10n.yearlySpending(yearly.rub))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                            child: _infoChip(Icons.receipt_long,
                                l10n.averageCheck(avgCheck.rub))),
                        const SizedBox(width: 12),
                        Flexible(
                            child: _infoChip(
                                Icons.timer,
                                l10n.nextPayment(
                                    nextPayment?.dayMonth ?? '—'))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
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
                          Text(l10n.walletBalance(wallet.balance.rub),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            l10n.walletSufficientFor(monthlyCost > 0
                                ? (wallet.balance / monthlyCost).floor()
                                : 0),
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Text('vs рынок (2500 ₽)',
                        style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.quickActions,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                QuickActionButton(
                    icon: Icons.add,
                    label: l10n.addSubscription,
                    onTap: () => context.push('/subscriptions')),
                QuickActionButton(
                    icon: Icons.calendar_month,
                    label: l10n.calendar,
                    onTap: () => context.push('/calendar')),
                QuickActionButton(
                    icon: Icons.history,
                    label: l10n.history,
                    onTap: () => context.push('/history')),
                QuickActionButton(
                    icon: Icons.download,
                    label: l10n.export,
                    onTap: () async {
                      final csv = ref.read(subscriptionsCsvProvider);
                      await shareCsvFile(csv, 'subscriptions.csv');
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.dataExported)));
                    }),
              ],
            ),
            const SizedBox(height: 24),
            Text(l10n.upcomingPayments,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...upcoming.map((s) => SubscriptionListTile(
                  subscription: s,
                  onTap: () => context.push('/subscriptions/${s.id}'),
                )),
            const SizedBox(height: 24),
            Text(l10n.categories,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (categories.isNotEmpty) ...[
              Column(
                children: categories.entries.map((e) {
                  final total =
                      categories.values.fold<double>(0, (a, b) => a + b);
                  final percent = total > 0
                      ? (e.value / total * 100).toStringAsFixed(0)
                      : '0';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(width: 80, child: Text(e.key)),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: total > 0 ? e.value / total : 0,
                              minHeight: 8,
                              backgroundColor: AppColors.divider,
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary),
                            ),
                          ),
                        ),
                        SizedBox(
                            width: 50,
                            child: Text('$percent%', textAlign: TextAlign.end)),
                        SizedBox(
                            width: 60,
                            child: Text(e.value.rub, textAlign: TextAlign.end)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ] else
              const Text('Нет категорий'),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
