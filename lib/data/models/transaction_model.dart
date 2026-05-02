/// Локальная SQLite-модель пополнений кошелька и списаний по подпискам.
class TransactionModel {
  const TransactionModel({
    this.id,
    this.subscriptionId,
    required this.type,
    required this.amountCents,
    this.currency = 'RUB',
    required this.occurredAt,
    this.note,
  });

  final int? id;
  final int? subscriptionId;
  final String type;
  final int amountCents;
  final String currency;
  final DateTime occurredAt;
  final String? note;

  /// Преобразует модель в строку SQLite.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'subscription_id': subscriptionId,
      'type': type,
      'amount_cents': amountCents,
      'currency': currency,
      'occurred_at': occurredAt.toIso8601String(),
      'note': note,
    };
  }

  /// Создаёт модель транзакции из строки SQLite.
  factory TransactionModel.fromMap(Map<String, Object?> map) {
    return TransactionModel(
      id: map['id'] as int?,
      subscriptionId: map['subscription_id'] as int?,
      type: map['type'] as String,
      amountCents: map['amount_cents'] as int,
      currency: map['currency'] as String,
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      note: map['note'] as String?,
    );
  }
}
