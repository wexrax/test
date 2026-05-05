// lib/presentation/screens/subscriptions/subscription_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/wallet_provider.dart';

class SubscriptionDetailScreen extends ConsumerWidget {
  final int id;
  const SubscriptionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sub = ref.watch(subscriptionByIdProvider(id));

    if (sub == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.detailTitle)),
        body: const Center(child: Text('Подписка не найдена')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.detailTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: _colorForLetter(sub.iconLetter),
              child: Text(
                sub.iconLetter,
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(sub.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Chip(label: Text(sub.category)),
            const SizedBox(height: 24),
            _detailRow('Сумма', sub.amount.rub),
            _detailRow(l10n.period,
                sub.period == 'monthly' ? 'Ежемесячно' : 'Ежегодно'),
            _detailRow('Следующее списание', sub.nextPaymentDate.dayMonth),
            _detailRow(l10n.status, sub.isActive ? 'Активна' : 'Архив'),
            _detailRow(
              l10n.yearlyAmount,
              (sub.period == 'yearly' ? sub.amount : sub.amount * 12).rub,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsPaid(context, ref, sub),
                    icon: const Icon(Icons.check),
                    label: Text(l10n.markAsPaid),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: редактировать
                  },
                  icon: const Icon(Icons.edit),
                  label: Text(l10n.edit),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _delete(context, ref, sub),
              icon: const Icon(Icons.delete, color: AppColors.danger),
              label: Text(
                l10n.cancelDelete,
                style: const TextStyle(color: AppColors.danger),
              ),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _markAsPaid(
      BuildContext context,
      WidgetRef ref,
      SubscriptionData sub,
      ) async {
    final l10n = AppLocalizations.of(context)!;
    final wallet = ref.read(walletNotifierProvider.notifier);
    final canDeduct = await wallet.deduct(sub.amount, sub.name,
        subscriptionId: sub.id);
    if (canDeduct) {
      final paid = await ref
          .read(subscriptionNotifierProvider.notifier)
          .markAsPaid(sub.id);
      if (paid && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paidSuccess)),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.insufficientFunds)),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.insufficientFunds)),
        );
      }
    }
  }

  Future<void> _delete(
      BuildContext context,
      WidgetRef ref,
      SubscriptionData sub,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog( // ← важно: используем ctx внутри
        title: const Text('Отменить подписку?'),
        content: const Text('Подписка уйдёт в архив.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), // контекст диалога
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Да'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(subscriptionNotifierProvider.notifier).delete(sub.id);
      if (context.mounted) context.pop();
    }
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