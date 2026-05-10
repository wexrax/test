// lib/presentation/screens/history/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/wallet_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedPeriod = 'month';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transactions =
        ref.watch(filteredTransactionsProvider(_selectedPeriod));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'month', label: Text('Месяц')),
                ButtonSegment(value: 'quarter', label: Text('Квартал')),
                ButtonSegment(value: 'year', label: Text('Год')),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (v) =>
                  setState(() => _selectedPeriod = v.first),
            ),
          ),
          Expanded(
            child: transactions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Не удалось загрузить историю')),
              data: (transactions) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.totalForPeriod(
                        transactions
                            .where((t) => t.type == 'payment')
                            .fold<double>(0, (sum, t) => sum + t.amount)
                            .rub,
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (_, i) {
                        final t = transactions[i];
                        return ListTile(
                          title: Text(t.description),
                          subtitle: Text(t.date.dayMonth),
                          trailing: Text(
                            t.amount.rub,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
