// lib/presentation/screens/add_subscription/add_subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
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
  _SubscriptionTemplate(
      name: 'Netflix', category: 'Видео', amount: 799, period: 'monthly'),
  _SubscriptionTemplate(
      name: 'YouTube Premium',
      category: 'Видео',
      amount: 299,
      period: 'monthly'),
  _SubscriptionTemplate(
      name: 'Кинопоиск', category: 'Видео', amount: 399, period: 'monthly'),
  _SubscriptionTemplate(
      name: 'Okko', category: 'Видео', amount: 499, period: 'monthly'),
  _SubscriptionTemplate(
      name: 'Иви', category: 'Видео', amount: 399, period: 'monthly'),
  _SubscriptionTemplate(
      name: 'Wink', category: 'Видео', amount: 299, period: 'monthly'),
  // Музыка
  _SubscriptionTemplate(
      name: 'Spotify', category: 'Музыка', amount: 299, period: 'monthly'),
  _SubscriptionTemplate(
      name: 'Яндекс Музыка',
      category: 'Музыка',
      amount: 229,
      period: 'monthly'),
  _SubscriptionTemplate(
      name: 'VK Музыка', category: 'Музыка', amount: 149, period: 'monthly'),
  _SubscriptionTemplate(
      name: 'Apple Music', category: 'Музыка', amount: 169, period: 'monthly'),
  _SubscriptionTemplate(
      name: 'СберЗвук', category: 'Музыка', amount: 199, period: 'monthly'),
  // Облако
  _SubscriptionTemplate(
      name: 'Яндекс Диск', category: 'Облако', amount: 199, period: 'monthly'),
  _SubscriptionTemplate(
      name: 'Google One', category: 'Облако', amount: 239, period: 'monthly'),
  _SubscriptionTemplate(
      name: 'iCloud+', category: 'Облако', amount: 149, period: 'monthly'),
  _SubscriptionTemplate(
      name: 'Dropbox Plus', category: 'Облако', amount: 999, period: 'monthly'),
  _SubscriptionTemplate(
      name: 'Облако Mail.ru',
      category: 'Облако',
      amount: 99,
      period: 'monthly'),
];

class AddSubscriptionScreen extends ConsumerWidget {
  const AddSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Группируем шаблоны по категориям
    final grouped = <String, List<_SubscriptionTemplate>>{};
    for (final t in _templates) {
      grouped.putIfAbsent(t.category, () => []).add(t);
    }
    final categories = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addSubscriptionTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final sub = await _createCustomSubscription(context);
                  if (sub == null || !context.mounted) return;
                  await _addSubscription(context, ref, sub);
                },
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.22),
                    child: Icon(
                      Icons.edit_note,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  title: Text(
                    l10n.customSubscriptionTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(l10n.customSubscriptionSubtitle),
                  trailing: const Icon(Icons.add_circle_outline),
                ),
              ),
            ),
          ),
          for (final category in categories)
            Column(
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
                ...grouped[category]!.map((template) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.2),
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
                        final sub = await _configureSubscription(
                          context,
                          template,
                        );
                        if (sub == null || !context.mounted) return;
                        await _addSubscription(context, ref, sub);
                      },
                    )),
              ],
            ),
        ],
      ),
    );
  }

  Future<SubscriptionData?> _createCustomSubscription(BuildContext context) {
    return showModalBottomSheet<SubscriptionData>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CustomSubscriptionSheet(),
    );
  }

  Future<void> _addSubscription(
    BuildContext context,
    WidgetRef ref,
    SubscriptionData sub,
  ) async {
    final shouldAdd = await _confirmBudgetOverflow(context, ref, sub);
    if (!shouldAdd || !context.mounted) return;

    await ref.read(subscriptionNotifierProvider.notifier).add(sub);
    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.subscriptionAdded(sub.name)),
        duration: const Duration(seconds: 1),
      ),
    );
    // Возвращаемся на дашборд
    context.go('/dashboard');
  }

  Future<SubscriptionData?> _configureSubscription(
    BuildContext context,
    _SubscriptionTemplate template,
  ) {
    final now = DateTime.now();
    var nextPaymentDate = now.add(const Duration(days: 30));
    var hasTrial = false;
    var trialEndAt = now.add(const Duration(days: 14));
    var cancelAfterTrial = false;

    return showModalBottomSheet<SubscriptionData>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> pickNextPaymentDate() async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: nextPaymentDate,
                firstDate: DateTime(now.year, now.month, now.day),
                lastDate: DateTime(now.year + 5, now.month, now.day),
              );
              if (picked != null) {
                setState(() => nextPaymentDate = picked);
              }
            }

            Future<void> pickTrialEndDate() async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: trialEndAt,
                firstDate: DateTime(now.year, now.month, now.day),
                lastDate: DateTime(now.year + 2, now.month, now.day),
              );
              if (picked != null) {
                setState(() {
                  trialEndAt = picked;
                  if (nextPaymentDate.isBefore(picked)) {
                    nextPaymentDate = picked;
                  }
                });
              }
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Первое списание'),
                      subtitle: Text(nextPaymentDate.dayMonth),
                      trailing: const Icon(Icons.calendar_month_outlined),
                      onTap: pickNextPaymentDate,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Пробный период'),
                      value: hasTrial,
                      onChanged: (value) {
                        setState(() {
                          hasTrial = value;
                          if (!value) cancelAfterTrial = false;
                        });
                      },
                    ),
                    if (hasTrial) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Окончание триала'),
                        subtitle: Text(trialEndAt.dayMonth),
                        trailing: const Icon(Icons.event_available_outlined),
                        onTap: pickTrialEndDate,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Отменить после триала'),
                        value: cancelAfterTrial,
                        onChanged: (value) =>
                            setState(() => cancelAfterTrial = value),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить'),
                        onPressed: () {
                          Navigator.pop(
                            ctx,
                            SubscriptionData(
                              id: 0,
                              name: template.name,
                              category: template.category,
                              amount: template.amount,
                              period: template.period,
                              nextPaymentDate: nextPaymentDate,
                              isActive: true,
                              trialStartAt: hasTrial ? now : null,
                              trialEndAt: hasTrial ? trialEndAt : null,
                              cancelAfterTrial: hasTrial && cancelAfterTrial,
                              lastUsedAt: now,
                              iconColor: AppColors.primary.toARGB32(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmBudgetOverflow(
    BuildContext context,
    WidgetRef ref,
    SubscriptionData subscription,
  ) async {
    final budget = double.tryParse(
      (ref.read(settingsProvider)['monthly_budget'] ?? '').replaceAll(',', '.'),
    );
    if (budget == null || budget <= 0) return true;

    final projectedMonthly = ref.read(monthlyCostProvider) +
        monthlyAmountForSubscription(subscription);
    if (projectedMonthly <= budget) return true;

    final overrun = projectedMonthly - budget;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Лимит будет превышен'),
        content: Text(
          'Бюджет будет превышен на ${overrun.rub}. Всё равно добавить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    return confirmed == true;
  }
}

class _CustomSubscriptionSheet extends StatefulWidget {
  const _CustomSubscriptionSheet();

  @override
  State<_CustomSubscriptionSheet> createState() =>
      _CustomSubscriptionSheetState();
}

class _CustomSubscriptionSheetState extends State<_CustomSubscriptionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _amountController;
  late final DateTime _createdAt;
  late DateTime _nextPaymentDate;
  late DateTime _trialEndAt;
  String _period = 'monthly';
  bool _hasTrial = false;
  bool _cancelAfterTrial = false;

  @override
  void initState() {
    super.initState();
    _createdAt = DateTime.now();
    _nextPaymentDate = _createdAt.add(const Duration(days: 30));
    _trialEndAt = _createdAt.add(const Duration(days: 14));
    _nameController = TextEditingController();
    _categoryController = TextEditingController();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.customSubscriptionTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.name,
                    hintText: l10n.customSubscriptionNameHint,
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return l10n.customSubscriptionNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.category,
                    hintText: l10n.customSubscriptionCategoryHint,
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return l10n.customSubscriptionCategoryRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.price,
                    prefixText: '₽ ',
                  ),
                  validator: (value) {
                    final amount = _parseAmount(value ?? '');
                    if ((value ?? '').trim().isEmpty) {
                      return l10n.customSubscriptionPriceRequired;
                    }
                    if (amount == null || amount <= 0) {
                      return l10n.customSubscriptionPriceInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _period,
                  decoration: InputDecoration(labelText: l10n.period),
                  items: [
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text(l10n.periodWeekly),
                    ),
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text(l10n.periodMonthly),
                    ),
                    DropdownMenuItem(
                      value: 'yearly',
                      child: Text(l10n.periodYearly),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _period = value);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.firstPaymentDate),
                  subtitle: Text(_nextPaymentDate.dayMonth),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: _pickNextPaymentDate,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.trialPeriod),
                  value: _hasTrial,
                  onChanged: (value) {
                    setState(() {
                      _hasTrial = value;
                      if (!value) _cancelAfterTrial = false;
                    });
                  },
                ),
                if (_hasTrial) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.trialEnd),
                    subtitle: Text(_trialEndAt.dayMonth),
                    trailing: const Icon(Icons.event_available_outlined),
                    onTap: _pickTrialEndDate,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.cancelAfterTrial),
                    value: _cancelAfterTrial,
                    onChanged: (value) =>
                        setState(() => _cancelAfterTrial = value),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addSubscription),
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickNextPaymentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextPaymentDate,
      firstDate: DateTime(_createdAt.year, _createdAt.month, _createdAt.day),
      lastDate: DateTime(_createdAt.year + 5, _createdAt.month, _createdAt.day),
    );
    if (picked == null) return;
    setState(() => _nextPaymentDate = picked);
  }

  Future<void> _pickTrialEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _trialEndAt,
      firstDate: DateTime(_createdAt.year, _createdAt.month, _createdAt.day),
      lastDate: DateTime(_createdAt.year + 2, _createdAt.month, _createdAt.day),
    );
    if (picked == null) return;
    setState(() {
      _trialEndAt = picked;
      if (_nextPaymentDate.isBefore(picked)) {
        _nextPaymentDate = picked;
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = _parseAmount(_amountController.text)!;
    Navigator.pop(
      context,
      SubscriptionData(
        id: 0,
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        amount: amount,
        period: _period,
        nextPaymentDate: _nextPaymentDate,
        isActive: true,
        trialStartAt: _hasTrial ? _createdAt : null,
        trialEndAt: _hasTrial ? _trialEndAt : null,
        cancelAfterTrial: _hasTrial && _cancelAfterTrial,
        lastUsedAt: _createdAt,
        iconColor: AppColors.primary.toARGB32(),
        createdAt: _createdAt,
        updatedAt: _createdAt,
      ),
    );
  }

  double? _parseAmount(String raw) {
    final normalized = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }
}
