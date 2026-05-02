import '../../domain/repositories/transaction_repository.dart';
import '../local/transaction_dao.dart';
import '../models/transaction_model.dart';

/// Реализация [TransactionRepository] на SQLite.
class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._dao);

  final TransactionDao _dao;

  @override
  Future<int> create(TransactionModel transaction) => _dao.create(transaction);

  @override
  Future<List<TransactionModel>> getRecent({int limit = 20}) {
    return _dao.getRecent(limit: limit);
  }

  @override
  Future<List<TransactionModel>> getByPeriod({
    required DateTime from,
    required DateTime to,
  }) {
    return _dao.getByPeriod(from: from, to: to);
  }

  @override
  Future<int> getTotalChargesByPeriod({
    required DateTime from,
    required DateTime to,
  }) {
    return _dao.getTotalChargesByPeriod(from: from, to: to);
  }
}
