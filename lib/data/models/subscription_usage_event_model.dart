class SubscriptionUsageEventModel {
  const SubscriptionUsageEventModel({
    this.id,
    required this.subscriptionId,
    required this.usedAt,
    required this.createdAt,
  });

  final int? id;
  final int subscriptionId;
  final DateTime usedAt;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'subscription_id': subscriptionId,
      'used_at': usedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SubscriptionUsageEventModel.fromMap(Map<String, Object?> map) {
    return SubscriptionUsageEventModel(
      id: map['id'] as int?,
      subscriptionId: map['subscription_id'] as int,
      usedAt: DateTime.parse(map['used_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
