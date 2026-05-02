/// Локальная SQLite-модель единственной строки кошелька пользователя.
class WalletModel {
  const WalletModel({
    this.id = 1,
    required this.balanceCents,
    required this.autoTopUpEnabled,
    required this.autoTopUpThresholdCents,
    required this.autoTopUpAmountCents,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int balanceCents;
  final bool autoTopUpEnabled;
  final int autoTopUpThresholdCents;
  final int autoTopUpAmountCents;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразует модель в строку SQLite.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'balance_cents': balanceCents,
      'auto_top_up_enabled': autoTopUpEnabled ? 1 : 0,
      'auto_top_up_threshold_cents': autoTopUpThresholdCents,
      'auto_top_up_amount_cents': autoTopUpAmountCents,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Создаёт модель кошелька из строки SQLite.
  factory WalletModel.fromMap(Map<String, Object?> map) {
    return WalletModel(
      id: map['id'] as int,
      balanceCents: map['balance_cents'] as int,
      autoTopUpEnabled: map['auto_top_up_enabled'] == 1,
      autoTopUpThresholdCents: map['auto_top_up_threshold_cents'] as int,
      autoTopUpAmountCents: map['auto_top_up_amount_cents'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
