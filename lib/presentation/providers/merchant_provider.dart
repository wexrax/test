import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/merchant_subscription_model.dart';
import '../../domain/repositories/merchant_subscription_repository.dart';
import 'repository_providers.dart';

class MerchantData {
  final int id;
  final String name;
  final String description;
  final double price;
  final String period;
  final int subscriberCount;
  final double earned;

  MerchantData({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.period,
    required this.subscriberCount,
    required this.earned,
  });

  MerchantData copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? period,
    int? subscriberCount,
    double? earned,
  }) {
    return MerchantData(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      period: period ?? this.period,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      earned: earned ?? this.earned,
    );
  }

  factory MerchantData.fromModel(MerchantSubscriptionModel model) {
    return MerchantData(
      id: model.id ?? 0,
      name: model.title,
      description: model.description ?? '',
      price: model.priceCents / 100,
      period: model.billingPeriod,
      subscriberCount: model.subscribersCount,
      earned: model.earnedCents / 100,
    );
  }

  MerchantSubscriptionModel toModel() {
    final now = DateTime.now();
    return MerchantSubscriptionModel(
      id: id == 0 ? null : id,
      title: name,
      description: description,
      priceCents: (price * 100).round(),
      billingPeriod: period,
      subscribersCount: subscriberCount,
      earnedCents: (earned * 100).round(),
      createdAt: now,
      updatedAt: now,
    );
  }
}

class MerchantState {
  final List<MerchantData> merchants;
  MerchantState(this.merchants);
}

class MerchantNotifier extends StateNotifier<MerchantState> {
  MerchantNotifier(this._repository) : super(MerchantState([])) {
    load();
  }

  final MerchantSubscriptionRepository _repository;

  Future<void> load() async {
    final merchants = await _repository.getAll();
    if (!mounted) return;
    state = MerchantState(merchants.map(MerchantData.fromModel).toList());
  }

  Future<void> add(MerchantData merchant) async {
    await _repository.create(merchant.toModel());
    await load();
  }

  Future<int> withdraw(int merchantId) async {
    final amount = await _repository.withdraw(merchantId);
    await load();
    return amount;
  }

  Future<void> clear() async => state = MerchantState([]);
}

final merchantNotifierProvider =
    StateNotifierProvider<MerchantNotifier, MerchantState>(
  (ref) => MerchantNotifier(ref.watch(merchantSubscriptionRepositoryProvider)),
);

final merchantsProvider = Provider<List<MerchantData>>((ref) {
  return ref.watch(merchantNotifierProvider).merchants;
});
