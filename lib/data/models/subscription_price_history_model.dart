class SubscriptionPriceHistoryModel {
  const SubscriptionPriceHistoryModel({
    this.id,
    required this.subscriptionId,
    required this.subscriptionTitle,
    required this.oldAmountCents,
    required this.newAmountCents,
    this.currency = 'RUB',
    required this.changedAt,
  });

  final int? id;
  final int? subscriptionId;
  final String subscriptionTitle;
  final int oldAmountCents;
  final int newAmountCents;
  final String currency;
  final DateTime changedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'subscription_id': subscriptionId,
      'subscription_title': subscriptionTitle,
      'old_amount_cents': oldAmountCents,
      'new_amount_cents': newAmountCents,
      'currency': currency,
      'changed_at': changedAt.toIso8601String(),
    };
  }

  factory SubscriptionPriceHistoryModel.fromMap(Map<String, Object?> map) {
    return SubscriptionPriceHistoryModel(
      id: map['id'] as int?,
      subscriptionId: map['subscription_id'] as int?,
      subscriptionTitle: map['subscription_title'] as String,
      oldAmountCents: map['old_amount_cents'] as int,
      newAmountCents: map['new_amount_cents'] as int,
      currency: map['currency'] as String,
      changedAt: DateTime.parse(map['changed_at'] as String),
    );
  }
}
