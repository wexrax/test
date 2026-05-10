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
            if (sub.trialEndAt != null)
              _detailRow('Триал до', sub.trialEndAt!.dayMonth),
            _detailRow(
              'Последнее использование',
              sub.lastUsedAt == null ? 'Нет отметок' : sub.lastUsedAt!.dayMonth,
            ),
            _detailRow(l10n.status, _statusText(sub)),
            if (sub.isPendingArchive)
              _detailRow(
                l10n.archiveScheduledAt(''),
                _formatArchiveAt(sub.archiveAt!),
              ),
            _detailRow(
              l10n.yearlyAmount,
              (sub.period == 'yearly' ? sub.amount : sub.amount * 12).rub,
            ),
            const SizedBox(height: 24),
            if (sub.isVisibleActive) ...[
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
                    onPressed: () => _editPrice(context, ref, sub),
                    icon: const Icon(Icons.edit),
                    label: Text(l10n.edit),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (sub.isVisibleActive)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _markUsed(context, ref, sub),
                      icon: const Icon(Icons.touch_app_outlined),
                      label: const Text('Использовал'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickArchiveDate(context, ref, sub),
                      icon: const Icon(Icons.timer_outlined),
                      label: Text(l10n.archiveTimer),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _archive(context, ref, sub),
                      icon: const Icon(Icons.archive_outlined),
                      label: Text(l10n.cancelSubscription),
                    ),
                  ),
                ],
              )
            else if (sub.isPendingArchive)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _clearArchiveTimer(context, ref, sub),
                      icon: const Icon(Icons.timer_off_outlined),
                      label: Text(l10n.clearArchiveTimer),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _archive(context, ref, sub),
                      icon: const Icon(Icons.archive_outlined),
                      label: const Text('Архивировать сейчас'),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _restore(context, ref, sub),
                  icon: const Icon(Icons.unarchive_outlined),
                  label: Text(l10n.restoreSubscription),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _delete(context, ref, sub),
                icon: const Icon(Icons.delete, color: AppColors.danger),
                label: Text(
                  l10n.deleteSubscription,
                  style: const TextStyle(color: AppColors.danger),
                ),
                style:
                    OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatArchiveAt(DateTime archiveAt) {
    final day = archiveAt.day.toString().padLeft(2, '0');
    final month = archiveAt.month.toString().padLeft(2, '0');
    final hour = archiveAt.hour.toString().padLeft(2, '0');
    final minute = archiveAt.minute.toString().padLeft(2, '0');
    return '$day.$month.${archiveAt.year}, $hour:$minute';
  }

  String _statusText(SubscriptionData sub) {
    if (sub.isPendingArchive) return 'Архивируется';
    if (sub.isActive) return 'Активна';
    return 'Архив';
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
    final canDeduct =
        await wallet.deduct(sub.amount, sub.name, subscriptionId: sub.id);
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

  Future<void> _markUsed(
    BuildContext context,
    WidgetRef ref,
    SubscriptionData sub,
  ) async {
    await ref.read(subscriptionNotifierProvider.notifier).markUsed(sub.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Использование отмечено')),
      );
    }
  }

  Future<void> _editPrice(
    BuildContext context,
    WidgetRef ref,
    SubscriptionData sub,
  ) async {
    final controller = TextEditingController(
      text: sub.amount.toStringAsFixed(0),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Изменить цену'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Сумма',
            suffixText: '₽',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );
              if (parsed == null || parsed < 0) return;
              Navigator.pop(ctx, parsed);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value == sub.amount) return;
    await ref
        .read(subscriptionNotifierProvider.notifier)
        .update(sub.copyWith(amount: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Цена обновлена')),
      );
    }
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    SubscriptionData sub,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelSubscriptionTitle),
        content: Text(l10n.cancelSubscriptionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(subscriptionNotifierProvider.notifier).archive(sub.id);
    }
  }

  Future<void> _pickArchiveDate(
    BuildContext context,
    WidgetRef ref,
    SubscriptionData sub,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final currentTimer = sub.archiveAt;
    final initialDate = currentTimer != null && currentTimer.isAfter(firstDate)
        ? currentTimer
        : firstDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5, now.month, now.day),
    );
    if (picked == null) return;

    if (!context.mounted) return;
    final initialTime = currentTimer != null && currentTimer.isAfter(now)
        ? TimeOfDay.fromDateTime(currentTimer)
        : TimeOfDay.fromDateTime(now.add(const Duration(minutes: 5)));
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime == null) return;

    final archiveAt = DateTime(
      picked.year,
      picked.month,
      picked.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    if (!archiveAt.isAfter(DateTime.now())) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выберите будущее время архивации')),
        );
      }
      return;
    }

    await ref
        .read(subscriptionNotifierProvider.notifier)
        .scheduleArchive(sub.id, archiveAt);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.archiveTimerSaved)),
      );
    }
  }

  Future<void> _clearArchiveTimer(
    BuildContext context,
    WidgetRef ref,
    SubscriptionData sub,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(subscriptionNotifierProvider.notifier).clearArchiveTimer(
          sub.id,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.archiveTimerCleared)),
      );
    }
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    SubscriptionData sub,
  ) async {
    await ref.read(subscriptionNotifierProvider.notifier).restore(sub.id);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SubscriptionData sub,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSubscriptionTitle),
        content: Text(l10n.deleteSubscriptionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteSubscription),
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
