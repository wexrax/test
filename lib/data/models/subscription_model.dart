/// Локальная SQLite-модель регулярной подписки пользователя.
class SubscriptionModel {
  const SubscriptionModel({
    this.id,
    required this.title,
    required this.category,
    required this.amountCents,
    this.currency = 'RUB',
    required this.billingPeriod,
    required this.nextPaymentDate,
    this.status = 'active',
    required this.iconColor,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String title;
  final String category;
  final int amountCents;
  final String currency;
  final String billingPeriod;
  final DateTime nextPaymentDate;
  final String status;
  final int iconColor;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Показывать ли подписку в активных сценариях оплаты.
  bool get isActive => status == 'active';

  /// Преобразует модель в строку SQLite.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount_cents': amountCents,
      'currency': currency,
      'billing_period': billingPeriod,
      'next_payment_date': nextPaymentDate.toIso8601String(),
      'status': status,
      'icon_color': iconColor,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Создаёт модель подписки из строки SQLite.
  factory SubscriptionModel.fromMap(Map<String, Object?> map) {
    return SubscriptionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      amountCents: map['amount_cents'] as int,
      currency: map['currency'] as String,
      billingPeriod: map['billing_period'] as String,
      nextPaymentDate: DateTime.parse(map['next_payment_date'] as String),
      status: map['status'] as String,
      iconColor: map['icon_color'] as int,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Возвращает копию с заменёнными полями.
  SubscriptionModel copyWith({
    int? id,
    String? title,
    String? category,
    int? amountCents,
    String? currency,
    String? billingPeriod,
    DateTime? nextPaymentDate,
    String? status,
    int? iconColor,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amountCents: amountCents ?? this.amountCents,
      currency: currency ?? this.currency,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      status: status ?? this.status,
      iconColor: iconColor ?? this.iconColor,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
