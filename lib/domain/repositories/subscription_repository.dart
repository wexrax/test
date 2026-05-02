import '../../data/models/subscription_model.dart';

/// Контракт для управления подписками без раскрытия деталей SQLite.
abstract class SubscriptionRepository {
  /// Создаёт подписку и возвращает её идентификатор в базе.
  Future<int> create(SubscriptionModel subscription);

  /// Возвращает подписку по идентификатору или null, если её нет.
  Future<SubscriptionModel?> getById(int id);

  /// Возвращает подписки с необязательной фильтрацией по статусу.
  Future<List<SubscriptionModel>> getAll({String? status});

  /// Ищет подписки по названию с необязательной фильтрацией по статусу.
  Future<List<SubscriptionModel>> searchByTitle(String query, {String? status});

  /// Возвращает активные подписки, отсортированные по дате следующей оплаты.
  Future<List<SubscriptionModel>> getUpcoming({int limit = 4});

  /// Сохраняет изменения существующей подписки.
  Future<void> update(SubscriptionModel subscription);

  /// Переносит подписку в архив.
  Future<void> archive(int id);

  /// Восстанавливает архивную подписку.
  Future<void> restore(int id);

  /// Удаляет подписку по идентификатору.
  Future<void> delete(int id);

  /// Отмечает подписку как оплаченную и записывает транзакцию кошелька.
  Future<void> markAsPaid(int id);
}
