import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/savings_alternative_catalog.dart';
import '../../data/models/transaction_model.dart';
import 'repository_providers.dart';
import 'settings_provider.dart';
import 'subscription_provider.dart';
import 'wallet_provider.dart';

final analyticsSnapshotProvider =
    FutureProvider<AnalyticsSnapshot>((ref) async {
  final active = ref.watch(activeSubscriptionsProvider);
  final settings = ref.watch(settingsProvider);
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  ref.watch(
    walletNotifierProvider.select((state) => state.transactions.length),
  );

  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month);
  final transactions = await transactionRepository.getByPeriod(
    from: DateTime(currentMonth.year, currentMonth.month - 6),
    to: DateTime(currentMonth.year, currentMonth.month + 1),
  );

  return AnalyticsSnapshot.build(
    activeSubscriptions: active,
    transactions: transactions.map(_transactionDataFromModel).toList(),
    settings: settings,
    now: now,
  );
});

TransactionData _transactionDataFromModel(TransactionModel transaction) {
  return TransactionData(
    id: transaction.id ?? 0,
    type: transaction.type,
    amount: transaction.amountCents / 100,
    date: transaction.occurredAt,
    description: transaction.note ?? '',
    subscriptionId: transaction.subscriptionId,
  );
}

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.actualMonthSpent,
    required this.previousActualMonthSpent,
    required this.hasPreviousActualMonthSpent,
    required this.actualMonthChangePercent,
    required this.plannedMonthlyCost,
    required this.actualAverageCheck,
    required this.previousActualAverageCheck,
    required this.hasCurrentMonthCharges,
    required this.hasPreviousAverageCheck,
    required this.actualAverageCheckChangePercent,
    required this.yearlyForecast,
    required this.potentialSavings,
    required this.hasTransactionHistory,
    required this.months,
    required this.categories,
    required this.upcomingPayments,
    required this.trials,
    required this.inactiveSubscriptions,
    required this.recommendations,
    required this.monthlyBudget,
  });

  final double actualMonthSpent;
  final double previousActualMonthSpent;
  final bool hasPreviousActualMonthSpent;
  final int actualMonthChangePercent;
  final double plannedMonthlyCost;
  final double actualAverageCheck;
  final double previousActualAverageCheck;
  final bool hasCurrentMonthCharges;
  final bool hasPreviousAverageCheck;
  final int actualAverageCheckChangePercent;
  final double yearlyForecast;
  final double potentialSavings;
  final bool hasTransactionHistory;
  final List<AnalyticsMonthSpend> months;
  final List<AnalyticsCategorySpend> categories;
  final List<SubscriptionData> upcomingPayments;
  final List<SubscriptionData> trials;
  final List<InactiveSubscriptionInsight> inactiveSubscriptions;
  final List<SavingsRecommendation> recommendations;
  final double? monthlyBudget;

  double get budgetProgress {
    final budget = monthlyBudget;
    if (budget == null || budget <= 0) return 0;
    return (plannedMonthlyCost / budget).clamp(0.0, 1.0).toDouble();
  }

  bool get isBudgetExceeded {
    final budget = monthlyBudget;
    return budget != null && budget > 0 && plannedMonthlyCost > budget;
  }

  double get budgetOverrun {
    final budget = monthlyBudget;
    if (budget == null) return 0;
    return math.max(0, plannedMonthlyCost - budget);
  }

  static AnalyticsSnapshot build({
    required List<SubscriptionData> activeSubscriptions,
    required List<TransactionData> transactions,
    required Map<String, String> settings,
    required DateTime now,
  }) {
    final currentMonth = DateTime(now.year, now.month);
    final previousMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    final plannedMonthlyCost = activeSubscriptions.fold<double>(
      0,
      (sum, subscription) => sum + monthlyAmountForSubscription(subscription),
    );
    final previousActualMonthSpent =
        _chargeTotalForMonth(transactions, previousMonth);
    final previousChargeCount =
        _chargeCountForMonth(transactions, previousMonth);
    final actualAverageCheck = activeSubscriptions.isEmpty
        ? 0.0
        : plannedMonthlyCost / activeSubscriptions.length;
    final previousActualAverageCheck = previousChargeCount == 0
        ? 0.0
        : previousActualMonthSpent / previousChargeCount;
    final hiddenRecommendationKeys =
        hiddenSavingsRecommendationKeys(settings);
    final visibleRecommendations = _realRecommendationsFor(
      activeSubscriptions,
      hiddenRecommendationKeys,
    ).take(3).toList();
    final monthStarts = List.generate(
      7,
      (index) => DateTime(currentMonth.year, currentMonth.month - 6 + index),
    );
    final months = monthStarts.map((monthStart) {
      final isCurrentMonth = _isSameMonth(monthStart, currentMonth);
      return AnalyticsMonthSpend(
        monthStart: monthStart,
        label: _shortMonthLabel(monthStart.month),
        amount: isCurrentMonth
            ? plannedMonthlyCost
            : _chargeTotalForMonth(transactions, monthStart),
        subscriptions: _subscriptionsForMonth(
          monthStart: monthStart,
          currentMonth: currentMonth,
          activeSubscriptions: activeSubscriptions,
          transactions: transactions,
        ),
      );
    }).toList();

    return AnalyticsSnapshot(
      actualMonthSpent: plannedMonthlyCost,
      previousActualMonthSpent: previousActualMonthSpent,
      hasPreviousActualMonthSpent: previousActualMonthSpent > 0,
      actualMonthChangePercent: previousActualMonthSpent > 0
          ? _changePercent(plannedMonthlyCost, previousActualMonthSpent)
          : 0,
      plannedMonthlyCost: plannedMonthlyCost,
      actualAverageCheck: actualAverageCheck,
      previousActualAverageCheck: previousActualAverageCheck,
      hasCurrentMonthCharges: activeSubscriptions.isNotEmpty,
      hasPreviousAverageCheck: previousChargeCount > 0,
      actualAverageCheckChangePercent: previousActualAverageCheck > 0
          ? _changePercent(actualAverageCheck, previousActualAverageCheck)
          : 0,
      yearlyForecast: plannedMonthlyCost * 12,
      potentialSavings: visibleRecommendations.fold<double>(
        0,
        (sum, item) => sum + item.annualSavings,
      ),
      hasTransactionHistory: months.any((month) => month.amount > 0),
      months: months,
      categories: _categoryRows(
        activeSubscriptions,
        transactions,
        previousMonth,
      ),
      upcomingPayments: _upcoming(activeSubscriptions, 5),
      trials: _trialRows(activeSubscriptions, now),
      inactiveSubscriptions: _inactiveRows(activeSubscriptions, now),
      recommendations: visibleRecommendations,
      monthlyBudget: _parseBudget(settings['monthly_budget']),
    );
  }

  static List<AnalyticsSubscriptionSpend> _subscriptionsForMonth({
    required DateTime monthStart,
    required DateTime currentMonth,
    required List<SubscriptionData> activeSubscriptions,
    required List<TransactionData> transactions,
  }) {
    if (_isSameMonth(monthStart, currentMonth)) {
      return activeSubscriptions
          .map(
            (subscription) => AnalyticsSubscriptionSpend(
              id: subscription.id,
              name: subscription.name,
              amount: monthlyAmountForSubscription(subscription),
            ),
          )
          .toList();
    }

    final rows = <AnalyticsSubscriptionSpend>[];
    for (final transaction in _chargeTransactionsForMonth(
      transactions,
      monthStart,
    )) {
      final subscription = _matchSubscription(transaction, activeSubscriptions);
      rows.add(
        AnalyticsSubscriptionSpend(
          id: subscription?.id,
          name: subscription?.name ??
              (transaction.description.isEmpty
                  ? 'Списание'
                  : transaction.description),
          amount: transaction.amount,
        ),
      );
    }
    rows.sort((a, b) => b.amount.compareTo(a.amount));
    return rows;
  }

  static List<AnalyticsCategorySpend> _categoryRows(
    List<SubscriptionData> subscriptions,
    List<TransactionData> transactions,
    DateTime previousMonth,
  ) {
    final currentTotals = _categoryTotals(subscriptions);
    final previousTotals = _previousCategoryTotals(
      transactions,
      subscriptions,
      previousMonth,
    );
    final total = currentTotals.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    final rows = currentTotals.entries.map((entry) {
      final previous = previousTotals[entry.key] ?? 0;
      return AnalyticsCategorySpend(
        name: entry.key,
        amount: entry.value,
        percent: total <= 0 ? 0 : entry.value / total * 100,
        changePercent: previous > 0 ? _changePercent(entry.value, previous) : 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return rows;
  }

  static Map<String, double> _categoryTotals(
    List<SubscriptionData> subscriptions,
  ) {
    final totals = <String, double>{};
    for (final subscription in subscriptions) {
      totals.update(
        subscription.category,
        (value) => value + monthlyAmountForSubscription(subscription),
        ifAbsent: () => monthlyAmountForSubscription(subscription),
      );
    }
    return totals;
  }

  static Map<String, double> _previousCategoryTotals(
    List<TransactionData> transactions,
    List<SubscriptionData> subscriptions,
    DateTime monthStart,
  ) {
    final totals = <String, double>{};
    for (final transaction in _chargeTransactionsForMonth(
      transactions,
      monthStart,
    )) {
      final subscription = _matchSubscription(transaction, subscriptions);
      final category = subscription?.category;
      if (category == null) continue;
      totals.update(
        category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    return totals;
  }

  static List<SubscriptionData> _upcoming(
    List<SubscriptionData> subscriptions,
    int limit,
  ) {
    final sorted = [...subscriptions]
      ..sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
    return sorted.take(limit).toList();
  }

  static List<SubscriptionData> _trialRows(
    List<SubscriptionData> subscriptions,
    DateTime now,
  ) {
    return subscriptions
        .where((subscription) {
          final trialEnd = subscription.trialEndAt;
          return trialEnd != null && trialEnd.isAfter(now);
        })
        .toList()
      ..sort((a, b) => a.trialEndAt!.compareTo(b.trialEndAt!));
  }

  static List<InactiveSubscriptionInsight> _inactiveRows(
    List<SubscriptionData> subscriptions,
    DateTime now,
  ) {
    final rows = <InactiveSubscriptionInsight>[];
    for (final subscription in subscriptions) {
      if (subscription.isInactiveSuggestionHidden) continue;
      final baseline = subscription.lastUsedAt ?? subscription.createdAt;
      final inactiveDays = now.difference(baseline).inDays;
      if (inactiveDays > 30) {
        rows.add(
          InactiveSubscriptionInsight(
            subscription: subscription,
            inactiveDays: inactiveDays,
          ),
        );
      }
    }
    rows.sort((a, b) => b.inactiveDays.compareTo(a.inactiveDays));
    return rows;
  }

  static List<SavingsRecommendation> _realRecommendationsFor(
    List<SubscriptionData> subscriptions,
    Set<String> hiddenKeys,
  ) {
    final recommendations = <SavingsRecommendation>[];
    for (final subscription in subscriptions) {
      final subscriptionMonthly = monthlyAmountForSubscription(subscription);
      for (final alternative in savingsAlternativeCatalog) {
        if (!alternative.matches(
          serviceName: subscription.name,
          category: subscription.category,
        )) {
          continue;
        }
        if (alternative.monthlyPrice >= subscriptionMonthly) continue;
        final key = '${subscription.id}:${alternative.alternativeName}';
        if (hiddenKeys.contains(key)) continue;
        recommendations.add(
          SavingsRecommendation(
            key: key,
            subscription: subscription,
            alternativeName: alternative.alternativeName,
            alternativeMonthlyPrice: alternative.monthlyPrice,
            annualSavings:
                (subscriptionMonthly - alternative.monthlyPrice) * 12,
            url: alternative.url,
          ),
        );
      }
    }
    recommendations.sort((a, b) => b.annualSavings.compareTo(a.annualSavings));
    return recommendations;
  }

  static double _chargeTotalForMonth(
    List<TransactionData> transactions,
    DateTime monthStart,
  ) {
    return _chargeTransactionsForMonth(transactions, monthStart).fold<double>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );
  }

  static int _chargeCountForMonth(
    List<TransactionData> transactions,
    DateTime monthStart,
  ) {
    return _chargeTransactionsForMonth(transactions, monthStart).length;
  }

  static List<TransactionData> _chargeTransactionsForMonth(
    List<TransactionData> transactions,
    DateTime monthStart,
  ) {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1);
    return transactions.where((transaction) {
      return _isChargeTransaction(transaction) &&
          !transaction.date.isBefore(monthStart) &&
          transaction.date.isBefore(monthEnd);
    }).toList();
  }

  static bool _isChargeTransaction(TransactionData transaction) {
    return transaction.type == 'payment' || transaction.type == 'charge';
  }

  static SubscriptionData? _matchSubscription(
    TransactionData transaction,
    List<SubscriptionData> subscriptions,
  ) {
    for (final subscription in subscriptions) {
      if (transaction.subscriptionId == subscription.id) return subscription;
    }
    final normalizedDescription = normalizeCatalogText(transaction.description);
    for (final subscription in subscriptions) {
      if (normalizedDescription == normalizeCatalogText(subscription.name)) {
        return subscription;
      }
    }
    return null;
  }

  static bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static double? _parseBudget(String? value) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  static int _changePercent(double current, double previous) {
    if (previous <= 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous * 100).round();
  }

  static String _shortMonthLabel(int month) {
    const labels = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    return labels[month - 1];
  }
}

class AnalyticsMonthSpend {
  const AnalyticsMonthSpend({
    required this.monthStart,
    required this.label,
    required this.amount,
    required this.subscriptions,
  });

  final DateTime monthStart;
  final String label;
  final double amount;
  final List<AnalyticsSubscriptionSpend> subscriptions;
}

class AnalyticsSubscriptionSpend {
  const AnalyticsSubscriptionSpend({
    required this.id,
    required this.name,
    required this.amount,
  });

  final int? id;
  final String name;
  final double amount;
}

class AnalyticsCategorySpend {
  const AnalyticsCategorySpend({
    required this.name,
    required this.amount,
    required this.percent,
    required this.changePercent,
  });

  final String name;
  final double amount;
  final double percent;
  final int changePercent;
}

class InactiveSubscriptionInsight {
  const InactiveSubscriptionInsight({
    required this.subscription,
    required this.inactiveDays,
  });

  final SubscriptionData subscription;
  final int inactiveDays;
}

class SavingsRecommendation {
  const SavingsRecommendation({
    required this.key,
    required this.subscription,
    required this.alternativeName,
    required this.alternativeMonthlyPrice,
    required this.annualSavings,
    required this.url,
  });

  final String key;
  final SubscriptionData subscription;
  final String alternativeName;
  final double alternativeMonthlyPrice;
  final double annualSavings;
  final String url;
}
