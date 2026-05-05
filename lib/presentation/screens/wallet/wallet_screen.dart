// lib/presentation/screens/wallet/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/wallet_provider.dart';

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
          Text(
            l10n.walletBalance(state.balance.rub),
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Автопополнение ${state.autoTopUpEnabled ? "включено" : "выключено"}',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showTopUpOptions(context, ref),
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
                            color: isTopUp ? AppColors.success : AppColors.danger,
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

  // ───────── Пополнение: выбор способа ─────────
  void _showTopUpOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Карта'),
                onTap: () {
                  Navigator.pop(ctx); // закрываем bottom sheet
                  _showCardTopUpDialog(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text('СБП'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSbpTopUpDialog(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────── Диалог пополнения через карту ─────────
  void _showCardTopUpDialog(BuildContext parentContext, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final cardNumberCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    final cardMask = MaskTextInputFormatter(
      mask: '#### #### #### ####',
      filter: {"#": RegExp(r'[0-9]')},
    );
    final expiryMask = MaskTextInputFormatter(
      mask: '##/##',
      filter: {"#": RegExp(r'[0-9]')},
    );

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Пополнить с карты'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: cardNumberCtrl,
                  inputFormatters: [cardMask],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Номер карты',
                    hintText: '0000 0000 0000 0000',
                  ),
                  validator: (v) =>
                  v == null || v.replaceAll(' ', '').length < 16
                      ? 'Введите номер карты'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: expiryCtrl,
                        inputFormatters: [expiryMask],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Срок',
                          hintText: 'ММ/ГГ',
                        ),
                        validator: (v) =>
                        v == null || v.length < 5 ? 'Введите срок' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: cvvCtrl,
                        maxLength: 3,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          hintText: '123',
                        ),
                        validator: (v) =>
                        v == null || v.length < 3 ? 'Введите CVV' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Сумма',
                    hintText: '1000',
                  ),
                  validator: (v) {
                    final amount = double.tryParse(v ?? '');
                    return amount == null || amount <= 0
                        ? 'Введите сумму'
                        : null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final amount = double.parse(amountCtrl.text);
                await ref.read(walletNotifierProvider.notifier).topUp(amount);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: const Text('Пополнить'),
          ),
        ],
      ),
    );
  }

  // ───────── Диалог пополнения через СБП ─────────
  void _showSbpTopUpDialog(BuildContext parentContext, WidgetRef ref) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Пополнить через СБП'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Сумма',
            hintText: '500',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount > 0) {
                await ref.read(walletNotifierProvider.notifier).topUp(amount);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: const Text('Пополнить'),
          ),
        ],
      ),
    );
  }

  // ───────── Настройки автопополнения ─────────
  void _showAutoTopUpDialog(BuildContext context, WidgetRef ref) {
    final state = ref.read(walletNotifierProvider);
    final amountCtrl = TextEditingController(text: state.autoTopUpAmount.toStringAsFixed(0));
    final thresholdCtrl = TextEditingController(text: state.autoTopUpThreshold.toStringAsFixed(0));
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.autoTopUpSettings),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.amount),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: thresholdCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.threshold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text);
              final threshold = double.tryParse(thresholdCtrl.text);
              if (amount != null && threshold != null) {
                await ref
                    .read(walletNotifierProvider.notifier)
                    .updateAutoTopUp(threshold: threshold, amount: amount);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}