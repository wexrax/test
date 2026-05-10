// lib/presentation/screens/wallet/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/wallet_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(walletNotifierProvider);
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface.withValues(alpha: 0.7);
    final onSurfaceColor = theme.colorScheme.onSurface;

    final formattedBalance =
        NumberFormat.decimalPattern('ru').format(state.balance);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.walletTitle),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Карточка баланса и управления ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusExtraLarge),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.yourBudget,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onSurfaceColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$formattedBalance ₽',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: onSurfaceColor,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.sync,
                          size: 18,
                          color: state.autoTopUpEnabled
                              ? AppColors.success
                              : onSurfaceColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Автопополнение ${state.autoTopUpEnabled ? "включено" : "выключено"}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: onSurfaceColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Кнопки с новыми отступами и скруглением
                    Row(
                      children: [
                        Expanded(
                          child: _WalletActionButton(
                            icon: Icons.add,
                            label: l10n.topUp,
                            onTap: () => _showTopUpOptions(context, ref),
                          ),
                        ),
                        const SizedBox(width: 16), // увеличенный отступ
                        Expanded(
                          child: _WalletActionButton(
                            icon: Icons.settings,
                            label: l10n.autoTopUp,
                            onTap: () => _showAutoTopUpDialog(context, ref),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Заголовок «Последние операции» ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.transactionHistory,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: onSurfaceColor),
              ),
            ),
            const SizedBox(height: 12),

            // ── Список операций ──
            if (state.transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Пока нет операций',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onSurfaceColor.withValues(alpha: 0.6),
                  ),
                ),
              )
            else
              ...state.transactions.map(
                (t) => _TransactionTile(
                  transaction: t,
                  surfaceColor: surfaceColor,
                  onSurfaceColor: onSurfaceColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────── Методы пополнения и авто (без изменений) ───────

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
                  Navigator.pop(ctx);
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

  void _showAutoTopUpDialog(BuildContext context, WidgetRef ref) {
    final state = ref.read(walletNotifierProvider);
    final amountCtrl =
        TextEditingController(text: state.autoTopUpAmount.toStringAsFixed(0));
    final thresholdCtrl = TextEditingController(
        text: state.autoTopUpThreshold.toStringAsFixed(0));
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

// ─── Обновлённая кнопка для кошелька (как на дашборде) ───
class _WalletActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _WalletActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary
              .withValues(alpha: 0.75), // сплошной жёлтый, без прозрачности
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Виджет одной транзакции (без изменений) ───
class _TransactionTile extends StatelessWidget {
  final dynamic transaction;
  final Color surfaceColor;
  final Color onSurfaceColor;

  const _TransactionTile({
    required this.transaction,
    required this.surfaceColor,
    required this.onSurfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    final isTopUp = transaction.type == 'topup';
    final icon = isTopUp ? Icons.arrow_downward : Icons.arrow_upward;
    final color = isTopUp ? AppColors.success : AppColors.danger;
    final sign = isTopUp ? '+' : '-';
    final formattedAmount =
        NumberFormat.decimalPattern('ru').format(transaction.amount);
    final amount = '$sign$formattedAmount ₽';

    final dateFormatter = DateFormat('d MMMM', 'ru');
    final formattedDate = dateFormatter.format(transaction.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppDimens.radiusExtraLarge),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            transaction.description,
            style:
                TextStyle(color: onSurfaceColor, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            formattedDate,
            style: TextStyle(color: onSurfaceColor.withValues(alpha: 0.6)),
          ),
          trailing: Text(
            amount,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
