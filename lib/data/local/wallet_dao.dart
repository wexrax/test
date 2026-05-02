import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import 'app_database.dart';

/// Выполняет SQLite-запросы и изменения для единственной строки кошелька.
class WalletDao {
  const WalletDao(this._database);

  final AppDatabase _database;

  /// Загружает кошелёк пользователя.
  Future<WalletModel> getWallet() async {
    final db = await _database.database;
    final rows = await db.query('wallets', where: 'id = 1', limit: 1);
    return WalletModel.fromMap(rows.first);
  }

  /// Добавляет деньги в кошелёк и записывает соответствующую транзакцию.
  Future<void> topUp(int amountCents, {String note = 'Пополнение'}) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final now = DateTime.now();
      final wallet = await txn.query('wallets', where: 'id = 1', limit: 1);
      final balance = wallet.first['balance_cents'] as int;
      await txn.update('wallets', {
        'balance_cents': balance + amountCents,
        'updated_at': now.toIso8601String(),
      }, where: 'id = 1');
      await txn.insert(
        'transactions',
        TransactionModel(
          type: 'top_up',
          amountCents: amountCents,
          occurredAt: now,
          note: note,
        ).toMap()..remove('id'),
      );
    });
  }

  /// Обновляет настройки автопополнения.
  Future<void> configureAutoTopUp({
    required bool enabled,
    required int thresholdCents,
    required int amountCents,
  }) async {
    final db = await _database.database;
    await db.update('wallets', {
      'auto_top_up_enabled': enabled ? 1 : 0,
      'auto_top_up_threshold_cents': thresholdCents,
      'auto_top_up_amount_cents': amountCents,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = 1');
  }

  /// Выполняет автопополнение, если баланс ниже настроенного порога.
  Future<bool> applyAutoTopUpIfNeeded() async {
    final wallet = await getWallet();
    if (!wallet.autoTopUpEnabled ||
        wallet.balanceCents >= wallet.autoTopUpThresholdCents ||
        wallet.autoTopUpAmountCents <= 0) {
      return false;
    }

    await topUp(wallet.autoTopUpAmountCents, note: 'Автопополнение');
    return true;
  }
}
