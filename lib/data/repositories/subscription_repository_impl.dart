import '../../domain/repositories/subscription_repository.dart';
import '../local/subscription_dao.dart';
import '../models/subscription_model.dart';
import '../models/subscription_price_history_model.dart';

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
  Future<void> scheduleArchive(int id, DateTime archiveAt) {
    return _dao.scheduleArchive(id, archiveAt);
  }

  @override
  Future<void> clearArchiveTimer(int id) => _dao.clearArchiveTimer(id);

  @override
  Future<int> archiveDueSubscriptions(DateTime now) {
    return _dao.archiveDueSubscriptions(now);
  }

  @override
  Future<int> cancelDueTrials(DateTime now) {
    return _dao.cancelDueTrials(now);
  }

  @override
  Future<void> markAsPaid(int id) => _dao.markAsPaid(id);

  @override
  Future<void> markUsed(int id, {DateTime? usedAt}) {
    return _dao.markUsed(id, usedAt: usedAt);
  }

  @override
  Future<void> hideInactiveSuggestion(int id, {DateTime? hiddenAt}) {
    return _dao.hideInactiveSuggestion(id, hiddenAt: hiddenAt);
  }

  @override
  Future<void> setCancelAfterTrial(int id, bool value) {
    return _dao.setCancelAfterTrial(id, value);
  }

  @override
  Future<List<SubscriptionPriceHistoryModel>> getPriceHistory() {
    return _dao.getPriceHistory();
  }
}
