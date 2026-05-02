import '../../domain/repositories/merchant_subscription_repository.dart';
import '../local/merchant_subscription_dao.dart';
import '../models/merchant_subscription_model.dart';

/// Реализация [MerchantSubscriptionRepository] на SQLite.
class MerchantSubscriptionRepositoryImpl
    implements MerchantSubscriptionRepository {
  const MerchantSubscriptionRepositoryImpl(this._dao);

  final MerchantSubscriptionDao _dao;

  @override
  Future<int> create(MerchantSubscriptionModel subscription) {
    return _dao.create(subscription);
  }

  @override
  Future<List<MerchantSubscriptionModel>> getAll() => _dao.getAll();

  @override
  Future<void> update(MerchantSubscriptionModel subscription) {
    return _dao.update(subscription);
  }

  @override
  Future<void> delete(int id) => _dao.delete(id);

  @override
  Future<int> withdraw(int id) => _dao.withdraw(id);
}
