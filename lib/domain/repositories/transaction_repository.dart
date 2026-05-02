import '../../data/models/transaction_model.dart';

/// Контракт для чтения и записи истории транзакций кошелька.
abstract class TransactionRepository {
  /// Создаёт транзакцию и возвращает её идентификатор в базе.
  Future<int> create(TransactionModel transaction);

  /// Возвращает последние транзакции первыми.
  Future<List<TransactionModel>> getRecent({int limit = 20});

  /// Возвращает транзакции в полуоткрытом периоде [from, to).
  Future<List<TransactionModel>> getByPeriod({
    required DateTime from,
    required DateTime to,
  });

  /// Возвращает сумму транзакций списания в полуоткрытом периоде [from, to).
  Future<int> getTotalChargesByPeriod({
    required DateTime from,
    required DateTime to,
  });
}
