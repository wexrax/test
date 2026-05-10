// lib/presentation/providers/subscription_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/archive_timer_service.dart';
import '../../core/utils/export_utils.dart';
import '../../data/models/subscription_price_history_model.dart';
import '../../data/models/subscription_model.dart';
import '../../domain/repositories/subscription_repository.dart';
import 'repository_providers.dart';
import 'settings_provider.dart';
import 'wallet_provider.dart';

class SubscriptionData {
  final int id;
  final String name;
  final String category;
  final double amount;
  final String period; // 'monthly', 'yearly'
  final DateTime nextPaymentDate;
  final bool isActive;
  final DateTime? archiveAt;
  final DateTime? trialStartAt;
  final DateTime? trialEndAt;
  final bool cancelAfterTrial;
  final DateTime? lastUsedAt;
  final DateTime? inactiveSuggestionHiddenAt;
  final int iconColor;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionData({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.period,
    required this.nextPaymentDate,
    this.isActive = true,
    this.archiveAt,
    this.trialStartAt,
    this.trialEndAt,
    this.cancelAfterTrial = false,
    this.lastUsedAt,
    this.inactiveSuggestionHiddenAt,
    this.iconColor = 0xFF2F80ED,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get iconLetter => name.isNotEmpty ? name[0].toUpperCase() : '?';

  bool get isPendingArchive => isActive && archiveAt != null;

  bool get isVisibleActive => isActive && archiveAt == null;

  bool get isArchived => !isActive;

  bool get isTrial => trialEndAt != null && trialEndAt!.isAfter(DateTime.now());

  bool get isInactiveSuggestionHidden => inactiveSuggestionHiddenAt != null;

  SubscriptionData copyWith({
    int? id,
    String? name,
    String? category,
    double? amount,
    String? period,
    DateTime? nextPaymentDate,
    bool? isActive,
    DateTime? archiveAt,
    bool clearArchiveAt = false,
    DateTime? trialStartAt,
    bool clearTrialStartAt = false,
    DateTime? trialEndAt,
    bool clearTrialEndAt = false,
    bool? cancelAfterTrial,
    DateTime? lastUsedAt,
    bool clearLastUsedAt = false,
    DateTime? inactiveSuggestionHiddenAt,
    bool clearInactiveSuggestionHiddenAt = false,
    int? iconColor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionData(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      isActive: isActive ?? this.isActive,
      archiveAt: clearArchiveAt ? null : archiveAt ?? this.archiveAt,
      trialStartAt:
          clearTrialStartAt ? null : trialStartAt ?? this.trialStartAt,
      trialEndAt: clearTrialEndAt ? null : trialEndAt ?? this.trialEndAt,
      cancelAfterTrial: cancelAfterTrial ?? this.cancelAfterTrial,
      lastUsedAt: clearLastUsedAt ? null : lastUsedAt ?? this.lastUsedAt,
      inactiveSuggestionHiddenAt: clearInactiveSuggestionHiddenAt
          ? null
          : inactiveSuggestionHiddenAt ?? this.inactiveSuggestionHiddenAt,
      iconColor: iconColor ?? this.iconColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SubscriptionData.fromModel(SubscriptionModel model) {
    return SubscriptionData(
      id: model.id ?? 0,
      name: model.title,
      category: model.category,
      amount: model.amountCents / 100,
      period: model.billingPeriod,
      nextPaymentDate: model.nextPaymentDate,
      isActive: model.isActive,
      archiveAt: model.archiveAt,
      trialStartAt: model.trialStartAt,
      trialEndAt: model.trialEndAt,
      cancelAfterTrial: model.cancelAfterTrial,
      lastUsedAt: model.lastUsedAt,
      inactiveSuggestionHiddenAt: model.inactiveSuggestionHiddenAt,
      iconColor: model.iconColor,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  SubscriptionModel toModel() {
    final now = DateTime.now();
    return SubscriptionModel(
      id: id == 0 ? null : id,
      title: name,
      category: category,
      amountCents: (amount * 100).round(),
      billingPeriod: period,
      nextPaymentDate: nextPaymentDate,
      status: isActive ? 'active' : 'archived',
      archiveAt: archiveAt,
      trialStartAt: trialStartAt,
      trialEndAt: trialEndAt,
      cancelAfterTrial: cancelAfterTrial,
      lastUsedAt: lastUsedAt,
      inactiveSuggestionHiddenAt: inactiveSuggestionHiddenAt,
      iconColor: iconColor,
      createdAt: createdAt,
      updatedAt: now,
    );
  }
}

class SubscriptionState {
  final List<SubscriptionData> subscriptions;
  SubscriptionState(this.subscriptions);
}

class SubscriptionPriceHistoryData {
  const SubscriptionPriceHistoryData({
    required this.id,
    required this.subscriptionId,
    required this.subscriptionTitle,
    required this.oldAmount,
    required this.newAmount,
    required this.currency,
    required this.changedAt,
  });

  final int id;
  final int? subscriptionId;
  final String subscriptionTitle;
  final double oldAmount;
  final double newAmount;
  final String currency;
  final DateTime changedAt;

  factory SubscriptionPriceHistoryData.fromModel(
    SubscriptionPriceHistoryModel model,
  ) {
    return SubscriptionPriceHistoryData(
      id: model.id ?? 0,
      subscriptionId: model.subscriptionId,
      subscriptionTitle: model.subscriptionTitle,
      oldAmount: model.oldAmountCents / 100,
      newAmount: model.newAmountCents / 100,
      currency: model.currency,
      changedAt: model.changedAt,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier(this._repository, this._ref)
      : super(SubscriptionState([])) {
    load();
  }

  final SubscriptionRepository _repository;
  final Ref _ref;

  Future<void> load() async {
    final now = DateTime.now();
    await _repository.archiveDueSubscriptions(now);
    await _repository.cancelDueTrials(now);
    final subscriptions = await _repository.getAll();
    if (!mounted) return;
    final data = subscriptions.map(SubscriptionData.fromModel).toList();
    state = SubscriptionState(
      data,
    );
    await _syncArchiveTimers(data);
  }

  Future<void> add(SubscriptionData sub) async {
    await _repository.create(sub.toModel());
    await load();
  }

  Future<void> update(SubscriptionData updated) async {
    await _repository.update(updated.toModel());
    await load();
  }

  Future<void> archive(int id) async {
    await _repository.archive(id);
    await ArchiveTimerService.instance.cancel(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await ArchiveTimerService.instance.cancel(id);
    await load();
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    await ArchiveTimerService.instance.cancel(id);
    await load();
  }

  Future<void> scheduleArchive(int id, DateTime archiveAt) async {
    await _repository.scheduleArchive(id, archiveAt);
    final subscription = await _repository.getById(id);
    if (subscription != null &&
        subscription.isActive &&
        subscription.archiveAt == archiveAt) {
      await ArchiveTimerService.instance.schedule(
        subscriptionId: id,
        subscriptionName: subscription.title,
        archiveAt: archiveAt,
        timezone: _timezone,
        onDue: _reloadAfterArchiveTimer,
      );
    }
    await load();
  }

  Future<void> clearArchiveTimer(int id) async {
    await _repository.clearArchiveTimer(id);
    await ArchiveTimerService.instance.cancel(id);
    await load();
  }

  Future<int> archiveDueSubscriptions() async {
    final now = DateTime.now();
    final archived = await _repository.archiveDueSubscriptions(now);
    final trialCancelled = await _repository.cancelDueTrials(now);
    final count = archived + trialCancelled;
    if (count > 0) {
      await load();
    }
    return count;
  }

  Future<bool> markAsPaid(int id) async {
    try {
      await _repository.markAsPaid(id);
    } on StateError {
      return false;
    }
    await load();
    await _ref.read(walletNotifierProvider.notifier).load();
    return true;
  }

  Future<void> markUsed(int id) async {
    await _repository.markUsed(id);
    await load();
  }

  Future<void> hideInactiveSuggestion(int id) async {
    await _repository.hideInactiveSuggestion(id);
    await load();
  }

  Future<void> setCancelAfterTrial(int id, bool value) async {
    await _repository.setCancelAfterTrial(id, value);
    await load();
  }

  Future<void> clear() async {
    state = SubscriptionState([]);
  }

  String get _timezone {
    return _ref.read(settingsProvider)['timezone'] ?? 'Europe/Moscow';
  }

  Future<void> _syncArchiveTimers(List<SubscriptionData> subscriptions) async {
    final now = DateTime.now();
    for (final subscription in subscriptions) {
      final archiveAt = subscription.archiveAt;
      if (subscription.isActive &&
          archiveAt != null &&
          archiveAt.isAfter(now)) {
        await ArchiveTimerService.instance.schedule(
          subscriptionId: subscription.id,
          subscriptionName: subscription.name,
          archiveAt: archiveAt,
          timezone: _timezone,
          onDue: _reloadAfterArchiveTimer,
        );
      } else {
        await ArchiveTimerService.instance.cancel(subscription.id);
      }
    }
  }

  Future<void> _reloadAfterArchiveTimer() async {
    if (!mounted) return;
    await load();
  }
}

final subscriptionNotifierProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>(
  (ref) => SubscriptionNotifier(ref.watch(subscriptionRepositoryProvider), ref),
);

final activeSubscriptionsProvider = Provider<List<SubscriptionData>>((ref) {
  return visibleActiveSubscriptions(
    ref.watch(subscriptionNotifierProvider).subscriptions,
  );
});

final allSubscriptionsProvider = Provider<List<SubscriptionData>>((ref) {
  return ref.watch(subscriptionNotifierProvider).subscriptions;
});

final archivedSubscriptionsProvider = Provider<List<SubscriptionData>>((ref) {
  return archiveSystemSubscriptions(
    ref.watch(subscriptionNotifierProvider).subscriptions,
  );
});

List<SubscriptionData> visibleActiveSubscriptions(
  Iterable<SubscriptionData> subscriptions,
) {
  return subscriptions.where((s) => s.isVisibleActive).toList();
}

List<SubscriptionData> archiveSystemSubscriptions(
  Iterable<SubscriptionData> subscriptions,
) {
  return subscriptions
      .where((s) => s.isPendingArchive || s.isArchived)
      .toList();
}

double monthlyAmountForSubscription(SubscriptionData subscription) {
  switch (subscription.period) {
    case 'weekly':
      return subscription.amount * 52 / 12;
    case 'yearly':
      return subscription.amount / 12;
    case 'monthly':
    default:
      return subscription.amount;
  }
}

double yearlyAmountForSubscription(SubscriptionData subscription) {
  switch (subscription.period) {
    case 'weekly':
      return subscription.amount * 52;
    case 'yearly':
      return subscription.amount;
    case 'monthly':
    default:
      return subscription.amount * 12;
  }
}

final upcomingSubscriptionsProvider =
    Provider.family<List<SubscriptionData>, int>((ref, limit) {
  final active = ref.watch(activeSubscriptionsProvider);
  final sorted = [...active]
    ..sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
  return sorted.take(limit).toList();
});

final subscriptionByIdProvider =
    Provider.family<SubscriptionData?, int>((ref, id) {
  final all = ref.watch(allSubscriptionsProvider);
  try {
    return all.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
});

final subscriptionPriceHistoryProvider =
    FutureProvider<List<SubscriptionPriceHistoryData>>((ref) async {
  ref.watch(subscriptionNotifierProvider.select((state) => state.subscriptions));
  final repository = ref.watch(subscriptionRepositoryProvider);
  final rows = await repository.getPriceHistory();
  return rows.map(SubscriptionPriceHistoryData.fromModel).toList();
});

final monthlyCostProvider = Provider<double>((ref) {
  return ref.watch(activeSubscriptionsProvider).fold<double>(
        0,
        (sum, s) => sum + monthlyAmountForSubscription(s),
      );
});

final yearlyCostProvider = Provider<double>((ref) {
  return ref.watch(activeSubscriptionsProvider).fold<double>(
        0,
        (sum, s) => sum + yearlyAmountForSubscription(s),
      );
});

final averageCheckProvider = Provider<double>((ref) {
  final active = ref.watch(activeSubscriptionsProvider);
  if (active.isEmpty) return 0;
  final total = active.fold<double>(
    0,
    (sum, s) => sum + monthlyAmountForSubscription(s),
  );
  return total / active.length;
});

final nextPaymentDateProvider = Provider<DateTime?>((ref) {
  final active = ref.watch(activeSubscriptionsProvider);
  if (active.isEmpty) return null;
  final sorted = [...active]
    ..sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
  return sorted.first.nextPaymentDate;
});

final categoryBreakdownProvider = Provider<Map<String, double>>((ref) {
  final active = ref.watch(activeSubscriptionsProvider);
  final map = <String, double>{};
  for (final s in active) {
    final monthly = monthlyAmountForSubscription(s);
    map.update(s.category, (v) => v + monthly, ifAbsent: () => monthly);
  }
  return map;
});

final subscriptionsCsvProvider = Provider<String>((ref) {
  final all = ref.watch(allSubscriptionsProvider);
  return buildSubscriptionsCsv(
    all.map((s) => SubscriptionCsvRow(
          name: s.name,
          category: s.category,
          amount: s.amount,
          period: s.period,
          nextPaymentDate: s.nextPaymentDate,
          status: s.isPendingArchive
              ? 'Архивируется'
              : s.isActive
                  ? 'Активна'
                  : 'Архив',
        )),
  );
});
