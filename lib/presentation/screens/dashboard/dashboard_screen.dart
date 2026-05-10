// lib/presentation/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/quick_action_button.dart';
import '../../../core/widgets/subscription_list_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/wallet_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final active = ref.watch(activeSubscriptionsProvider);
    final monthlyCost = ref.watch(monthlyCostProvider);
    final yearlyCost = ref.watch(yearlyCostProvider);
    final nextPayment = ref.watch(nextPaymentDateProvider);
    final upcoming = ref.watch(upcomingSubscriptionsProvider(4));
    final categories = ref.watch(categoryBreakdownProvider);
    final wallet = ref.watch(walletNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Дашборд',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Обзор подписок и кошелька',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(subscriptionNotifierProvider.notifier).load();
          await ref.read(walletNotifierProvider.notifier).load();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _PlanSummaryCard(
              monthlyCost: monthlyCost,
              yearlyCost: yearlyCost,
              activeCount: active.length,
              nextPayment: nextPayment,
              onAnalyticsTap: () => context.go('/analytics'),
            ),
            const SizedBox(height: 12),
            _WalletSummaryCard(
              balance: wallet.balance,
              monthlyCost: monthlyCost,
              onTap: () => context.go('/wallet'),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.quickActions,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.add_circle_outline,
                    label: l10n.addSubscription,
                    onTap: () => context.push('/add-subscription'),
                  ),
                ),
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.insights,
                    label: 'Аналитика',
                    onTap: () => context.go('/analytics'),
                  ),
                ),
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.calendar_month_outlined,
                    label: l10n.calendar,
                    onTap: () => context.push('/calendar'),
                  ),
                ),
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.history,
                    label: l10n.history,
                    onTap: () => context.push('/history'),
                  ),
                ),
              ],
            ),
            if (upcoming.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionHeader(
                title: l10n.upcomingPayments,
                actionLabel: 'Все',
                onAction: () => context.push('/calendar'),
              ),
              const SizedBox(height: 8),
              ...upcoming.map(
                (subscription) => SubscriptionListTile(
                  subscription: subscription,
                  onTap: () =>
                      context.push('/subscriptions/${subscription.id}'),
                ),
              ),
            ],
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'План по категориям',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...categories.entries.map(
                (entry) => _CategoryProgressRow(
                  name: entry.key,
                  amount: entry.value,
                  total: monthlyCost,
                ),
              ),
            ],
            if (active.isEmpty) ...[
              const SizedBox(height: 24),
              _EmptyStateCard(onAdd: () => context.push('/add-subscription')),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({
    required this.monthlyCost,
    required this.yearlyCost,
    required this.activeCount,
    required this.nextPayment,
    required this.onAnalyticsTap,
  });

  final double monthlyCost;
  final double yearlyCost;
  final int activeCount;
  final DateTime? nextPayment;
  final VoidCallback onAnalyticsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'План подписок',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Аналитика',
                  onPressed: onAnalyticsTap,
                  icon: const Icon(Icons.insights),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${monthlyCost.rub} / мес.',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.subscriptions,
                  label: '$activeCount активных',
                ),
                _InfoChip(
                  icon: Icons.calendar_today,
                  label: '${yearlyCost.rub} / год',
                ),
                _InfoChip(
                  icon: Icons.event_available,
                  label: nextPayment == null
                      ? 'нет списаний'
                      : 'ближайшее ${nextPayment!.dayMonth}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletSummaryCard extends StatelessWidget {
  const _WalletSummaryCard({
    required this.balance,
    required this.monthlyCost,
    required this.onTap,
  });

  final double balance;
  final double monthlyCost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthsCovered = monthlyCost > 0 ? (balance / monthlyCost).floor() : 0;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.walletBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.walletBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Кошелёк: ${balance.rub}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      monthlyCost > 0
                          ? 'Хватит примерно на $monthsCovered мес. подписок'
                          : 'Добавьте подписки, чтобы увидеть запас',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _CategoryProgressRow extends StatelessWidget {
  const _CategoryProgressRow({
    required this.name,
    required this.amount,
    required this.total,
  });

  final String name;
  final double amount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name)),
              Text(
                amount.rub,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 7,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.subscriptions_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              'Подписок пока нет',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Добавьте первую подписку, и здесь появится ваш общий план.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Добавить подписку'),
            ),
          ],
        ),
      ),
    );
  }
}
