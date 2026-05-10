import '../../data/models/subscription_model.dart';
import '../../data/models/subscription_price_history_model.dart';

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

  /// Сохраняет дату автоматического переноса подписки в архив.
  Future<void> scheduleArchive(int id, DateTime archiveAt);

  /// Убирает дату автоматического переноса подписки в архив.
  Future<void> clearArchiveTimer(int id);

  /// Архивирует все активные подписки с истёкшим таймером.
  Future<int> archiveDueSubscriptions(DateTime now);

  /// Архивирует активные подписки с истёкшим триалом и автоотменой.
  Future<int> cancelDueTrials(DateTime now);

  /// Отмечает подписку как оплаченную и записывает транзакцию кошелька.
  Future<void> markAsPaid(int id);

  /// Отмечает ручной факт использования подписки.
  Future<void> markUsed(int id, {DateTime? usedAt});

  /// Скрывает рекомендацию о неиспользуемой подписке.
  Future<void> hideInactiveSuggestion(int id, {DateTime? hiddenAt});

  /// Меняет флаг автоотмены после триала.
  Future<void> setCancelAfterTrial(int id, bool value);

  /// Возвращает историю изменения цен.
  Future<List<SubscriptionPriceHistoryModel>> getPriceHistory();
}
