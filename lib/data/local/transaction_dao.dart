import '../models/transaction_model.dart';
import 'app_database.dart';

/// Выполняет SQLite-запросы и изменения для истории кошелька и списаний.
class TransactionDao {
  const TransactionDao(this._database);

  final AppDatabase _database;

  /// Добавляет транзакцию и возвращает её сгенерированный идентификатор.
  Future<int> create(TransactionModel transaction) async {
    final db = await _database.database;
    final values = transaction.toMap()..remove('id');
    return db.insert('transactions', values);
  }

  /// Загружает последние транзакции первыми.
  Future<List<TransactionModel>> getRecent({int limit = 20}) async {
    final db = await _database.database;
    final rows = await db.query(
      'transactions',
      orderBy: 'occurred_at DESC',
      limit: limit,
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  /// Загружает транзакции в полуоткрытом периоде [from, to).
  Future<List<TransactionModel>> getByPeriod({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'transactions',
      where: 'occurred_at >= ? AND occurred_at < ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: 'occurred_at DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  /// Суммирует списания по подпискам в полуоткрытом периоде [from, to).
  Future<int> getTotalChargesByPeriod({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _database.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount_cents), 0) AS total
      FROM transactions
      WHERE type = ? AND occurred_at >= ? AND occurred_at < ?
      ''',
      ['charge', from.toIso8601String(), to.toIso8601String()],
    );
    return result.first['total'] as int;
  }
}
