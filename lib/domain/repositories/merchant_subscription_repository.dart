import '../../data/models/merchant_subscription_model.dart';

/// Контракт для управления подписками, созданными пользователем как мерчантом.
abstract class MerchantSubscriptionRepository {
  /// Создаёт мерчант-подписку и возвращает её идентификатор в базе.
  Future<int> create(MerchantSubscriptionModel subscription);

  /// Возвращает все мерчант-подписки текущего локального пользователя.
  Future<List<MerchantSubscriptionModel>> getAll();

  /// Сохраняет изменения существующей мерчант-подписки.
  Future<void> update(MerchantSubscriptionModel subscription);

  /// Удаляет мерчант-подписку по идентификатору.
  Future<void> delete(int id);

  /// Выводит доступный заработок и возвращает выведенную сумму в копейках.
  Future<int> withdraw(int id);
}
