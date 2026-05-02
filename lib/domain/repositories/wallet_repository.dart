import '../../data/models/wallet_model.dart';

/// Контракт для управления локальным кошельком пользователя.
abstract class WalletRepository {
  /// Возвращает единственный локальный кошелёк.
  Future<WalletModel> getWallet();

  /// Добавляет деньги в кошелёк и записывает транзакцию пополнения.
  Future<void> topUp(int amountCents, {String note = 'Пополнение'});

  /// Обновляет настройки автопополнения.
  Future<void> configureAutoTopUp({
    required bool enabled,
    required int thresholdCents,
    required int amountCents,
  });

  /// Выполняет автопополнение, если баланс кошелька ниже порога.
  Future<bool> applyAutoTopUpIfNeeded();
}
