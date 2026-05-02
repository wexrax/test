import '../../domain/repositories/subscription_repository.dart';
import '../local/subscription_dao.dart';
import '../models/subscription_model.dart';

/// Реализация [SubscriptionRepository] на SQLite.
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  const SubscriptionRepositoryImpl(this._dao);

  final SubscriptionDao _dao;

  @override
  Future<int> create(SubscriptionModel subscription) =>
      _dao.create(subscription);

  @override
  Future<SubscriptionModel?> getById(int id) => _dao.getById(id);

  @override
  Future<List<SubscriptionModel>> getAll({String? status}) {
    return _dao.getAll(status: status);
  }

  @override
  Future<List<SubscriptionModel>> searchByTitle(
    String query, {
    String? status,
  }) {
    return _dao.searchByTitle(query, status: status);
  }

  @override
  Future<List<SubscriptionModel>> getUpcoming({int limit = 4}) {
    return _dao.getUpcoming(limit: limit);
  }

  @override
  Future<void> update(SubscriptionModel subscription) =>
      _dao.update(subscription);

  @override
  Future<void> archive(int id) => _dao.archive(id);

  @override
  Future<void> restore(int id) => _dao.restore(id);

  @override
  Future<void> delete(int id) => _dao.delete(id);

  @override
  Future<void> markAsPaid(int id) => _dao.markAsPaid(id);
}
