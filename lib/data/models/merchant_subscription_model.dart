/// Локальная SQLite-модель подписочного продукта, созданного пользователем.
class MerchantSubscriptionModel {
  const MerchantSubscriptionModel({
    this.id,
    required this.title,
    this.description,
    required this.priceCents,
    this.currency = 'RUB',
    required this.billingPeriod,
    this.subscribersCount = 0,
    this.earnedCents = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String title;
  final String? description;
  final int priceCents;
  final String currency;
  final String billingPeriod;
  final int subscribersCount;
  final int earnedCents;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразует модель в строку SQLite.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price_cents': priceCents,
      'currency': currency,
      'billing_period': billingPeriod,
      'subscribers_count': subscribersCount,
      'earned_cents': earnedCents,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Создаёт модель мерчант-подписки из строки SQLite.
  factory MerchantSubscriptionModel.fromMap(Map<String, Object?> map) {
    return MerchantSubscriptionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      priceCents: map['price_cents'] as int,
      currency: map['currency'] as String,
      billingPeriod: map['billing_period'] as String,
      subscribersCount: map['subscribers_count'] as int,
      earnedCents: map['earned_cents'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
