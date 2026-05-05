// lib/presentation/providers/subscription_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/export_utils.dart';
import '../../data/models/subscription_model.dart';
import '../../domain/repositories/subscription_repository.dart';
import 'repository_providers.dart';
import 'wallet_provider.dart';

class SubscriptionData {
  final int id;
  final String name;
  final String category;
  final double amount;
  final String period; // 'monthly', 'yearly'
  final DateTime nextPaymentDate;
  final bool isActive;
  final int iconColor;

  SubscriptionData({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.period,
    required this.nextPaymentDate,
    this.isActive = true,
    this.iconColor = 0xFF2F80ED,
  });

  String get iconLetter => name.isNotEmpty ? name[0].toUpperCase() : '?';

  SubscriptionData copyWith({
    int? id,
    String? name,
    String? category,
    double? amount,
    String? period,
    DateTime? nextPaymentDate,
    bool? isActive,
    int? iconColor,
  }) {
    return SubscriptionData(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      isActive: isActive ?? this.isActive,
      iconColor: iconColor ?? this.iconColor,
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
      iconColor: model.iconColor,
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
      iconColor: iconColor,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class SubscriptionState {
  final List<SubscriptionData> subscriptions;
  SubscriptionState(this.subscriptions);
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier(this._repository, this._ref)
      : super(SubscriptionState([])) {
    load();
  }

  final SubscriptionRepository _repository;
  final Ref _ref;

  Future<void> load() async {
    final subscriptions = await _repository.getAll();
    if (!mounted) return;
    state = SubscriptionState(
      subscriptions.map(SubscriptionData.fromModel).toList(),
    );
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
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    await load();
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

  Future<void> clear() async {
    state = SubscriptionState([]);
  }
}

final subscriptionNotifierProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>(
  (ref) => SubscriptionNotifier(
      ref.watch(subscriptionRepositoryProvider), ref),
);

final activeSubscriptionsProvider = Provider<List<SubscriptionData>>((ref) {
  return ref
      .watch(subscriptionNotifierProvider)
      .subscriptions
      .where((s) => s.isActive)
      .toList();
});

final allSubscriptionsProvider = Provider<List<SubscriptionData>>((ref) {
  return ref.watch(subscriptionNotifierProvider).subscriptions;
});

final archivedSubscriptionsProvider = Provider<List<SubscriptionData>>((ref) {
  return ref
      .watch(subscriptionNotifierProvider)
      .subscriptions
      .where((s) => !s.isActive)
      .toList();
});

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

final monthlyCostProvider = Provider<double>((ref) {
  return ref.watch(activeSubscriptionsProvider).fold<double>(
        0,
        (sum, s) => sum + (s.period == 'monthly' ? s.amount : s.amount / 12),
      );
});

final yearlyCostProvider = Provider<double>((ref) {
  return ref.watch(activeSubscriptionsProvider).fold<double>(
        0,
        (sum, s) => sum + (s.period == 'yearly' ? s.amount : s.amount * 12),
      );
});

final averageCheckProvider = Provider<double>((ref) {
  final active = ref.watch(activeSubscriptionsProvider);
  if (active.isEmpty) return 0;
  final total = active.fold<double>(0, (sum, s) => sum + s.amount);
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
    final monthly =
        s.period == 'monthly' ? s.amount : s.amount / 12;
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
          status: s.isActive ? 'Активна' : 'Архив',
        )),
  );
});