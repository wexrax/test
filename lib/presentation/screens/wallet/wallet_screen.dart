import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/wallet_provider.dart';
import 'topup_modal.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(walletNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.walletTitle)),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Text(l10n.walletBalance(state.balance.rub),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Автопополнение ${state.autoTopUpEnabled ? "вкл" : "выкл"}',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showTopUpDialog(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.topUp),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _showAutoTopUpDialog(context, ref),
                icon: const Icon(Icons.settings),
                label: Text(l10n.autoTopUp),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(l10n.transactionHistory,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.transactions.length,
                    itemBuilder: (_, i) {
                      final t = state.transactions[i];
                      final isTopUp = t.type == 'topup';
                      return ListTile(
                        leading: Icon(
                          isTopUp ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isTopUp ? AppColors.success : AppColors.danger,
                        ),
                        title: Text(t.description),
                        subtitle: Text(t.date.dayMonth),
                        trailing: Text(
                          '${isTopUp ? '+' : '-'}${t.amount.rub}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isTopUp ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTopUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const TopUpModal(),
    );
  }

  void _showAutoTopUpDialog(BuildContext context, WidgetRef ref) {
    final state = ref.read(walletNotifierProvider);
    final thresholdCtrl = TextEditingController(
        text: state.autoTopUpThreshold.toStringAsFixed(0));
    final amountCtrl =
        TextEditingController(text: state.autoTopUpAmount.toStringAsFixed(0));
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.autoTopUpSettings),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: thresholdCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.threshold)),
            const SizedBox(height: 12),
            TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.amount)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              final threshold = double.tryParse(thresholdCtrl.text) ?? 1000;
              final amount = double.tryParse(amountCtrl.text) ?? 5000;
              await ref.read(walletNotifierProvider.notifier).updateAutoTopUp(
                  enabled: true, threshold: threshold, amount: amount);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}
