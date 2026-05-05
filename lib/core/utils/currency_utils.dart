// lib/core/utils/currency_utils.dart
extension CurrencyFormat on double {
  String get rub => '${toStringAsFixed(0)} ₽';
  String get rubDecimal => '${toStringAsFixed(2)} ₽';
}