import '../models/subscription_model.dart';
import '../models/subscription_price_history_model.dart';
import '../models/subscription_usage_event_model.dart';
import 'app_database.dart';

/// Выполняет SQLite-запросы и изменения для пользовательских подписок.
class SubscriptionDao {
  const SubscriptionDao(this._database);

  final AppDatabase _database;

  /// Добавляет подписку и возвращает её сгенерированный идентификатор.
  Future<int> create(SubscriptionModel subscription) async {
    final db = await _database.database;
    final values = subscription.toMap()..remove('id');
    return db.insert('subscriptions', values);
  }

  /// Загружает подписку по идентификатору или возвращает null, если её нет.
  Future<SubscriptionModel?> getById(int id) async {
    final db = await _database.database;
    final rows = await db.query(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return SubscriptionModel.fromMap(rows.first);
  }

  /// Загружает подписки с необязательной фильтрацией по статусу.
  Future<List<SubscriptionModel>> getAll({String? status}) async {
    final db = await _database.database;
    final rows = await db.query(
      'subscriptions',
      where: status == null ? null : 'status = ?',
      whereArgs: status == null ? null : [status],
      orderBy: 'next_payment_date ASC, title COLLATE NOCASE ASC',
    );
    return rows.map(SubscriptionModel.fromMap).toList();
  }

  /// Ищет подписки по названию с необязательной фильтрацией по статусу.
  Future<List<SubscriptionModel>> searchByTitle(
    String query, {
    String? status,
  }) async {
    final db = await _database.database;
    final normalizedQuery = '%${query.trim()}%';
    final rows = await db.query(
      'subscriptions',
      where: status == null
          ? 'title LIKE ? COLLATE NOCASE'
          : 'title LIKE ? COLLATE NOCASE AND status = ?',
      whereArgs: status == null ? [normalizedQuery] : [normalizedQuery, status],
      orderBy: 'title COLLATE NOCASE ASC',
    );
    return rows.map(SubscriptionModel.fromMap).toList();
  }

  /// Загружает ближайшие активные подписки к оплате.
  Future<List<SubscriptionModel>> getUpcoming({int limit = 4}) async {
    final db = await _database.database;
    final rows = await db.query(
      'subscriptions',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'next_payment_date ASC',
      limit: limit,
    );
    return rows.map(SubscriptionModel.fromMap).toList();
  }

  /// Обновляет существующую подписку.
  Future<void> update(SubscriptionModel subscription) async {
    final id = subscription.id;
    if (id == null) {
      throw ArgumentError('Subscription id is required for update.');
    }

    final db = await _database.database;
    await db.transaction((txn) async {
      final existingRows = await txn.query(
        'subscriptions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (existingRows.isEmpty) {
        throw StateError('Subscription with id $id was not found.');
      }

      final existing = SubscriptionModel.fromMap(existingRows.first);
      final now = DateTime.now();
      final values = subscription.copyWith(updatedAt: now).toMap()
        ..remove('id')
        ..remove('created_at');
      await txn.update(
        'subscriptions',
        values,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (existing.amountCents != subscription.amountCents) {
        await txn.insert(
          'subscription_price_history',
          SubscriptionPriceHistoryModel(
            subscriptionId: id,
            subscriptionTitle: subscription.title,
            oldAmountCents: existing.amountCents,
            newAmountCents: subscription.amountCents,
            currency: subscription.currency,
            changedAt: now,
          ).toMap()
            ..remove('id'),
        );
      }
    });
  }

  /// Переносит подписку из активного списка без удаления истории.
  Future<void> archive(int id) async {
    await _setStatus(id, 'archived', clearArchiveAt: true);
  }

  /// Возвращает архивную подписку в активный список.
  Future<void> restore(int id) async {
    await _setStatus(id, 'active', clearArchiveAt: true);
  }

  /// Удаляет подписку, сохраняя строки транзакций.
  Future<void> delete(int id) async {
    final db = await _database.database;
    await db.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
  }

  /// Сохраняет дату будущего автоматического переноса подписки в архив.
  Future<void> scheduleArchive(int id, DateTime archiveAt) async {
    final db = await _database.database;
    await db.update(
      'subscriptions',
      {
        'archive_at': archiveAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND status = ?',
      whereArgs: [id, 'active'],
    );
  }

  /// Убирает таймер автоматического переноса подписки в архив.
  Future<void> clearArchiveTimer(int id) async {
    final db = await _database.database;
    await db.update(
      'subscriptions',
      {
        'archive_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Архивирует активные подписки с истёкшим таймером.
  Future<int> archiveDueSubscriptions(DateTime now) {
    return _database.archiveDueSubscriptions(now);
  }

  Future<int> cancelDueTrials(DateTime now) {
    return _database.cancelDueTrials(now);
  }

  Future<void> markUsed(int id, {DateTime? usedAt}) async {
    final db = await _database.database;
    final now = DateTime.now();
    final effectiveUsedAt = usedAt ?? now;
    await db.transaction((txn) async {
      await txn.insert(
        'subscription_usage_events',
        SubscriptionUsageEventModel(
          subscriptionId: id,
          usedAt: effectiveUsedAt,
          createdAt: now,
        ).toMap()
          ..remove('id'),
      );
      await txn.update(
        'subscriptions',
        {
          'last_used_at': effectiveUsedAt.toIso8601String(),
          'inactive_suggestion_hidden_at': null,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> hideInactiveSuggestion(int id, {DateTime? hiddenAt}) async {
    final db = await _database.database;
    final now = hiddenAt ?? DateTime.now();
    await db.update(
      'subscriptions',
      {
        'inactive_suggestion_hidden_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setCancelAfterTrial(int id, bool value) async {
    final db = await _database.database;
    await db.update(
      'subscriptions',
      {
        'cancel_after_trial': value ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SubscriptionUsageEventModel>> getUsageEvents(int id) async {
    final db = await _database.database;
    final rows = await db.query(
      'subscription_usage_events',
      where: 'subscription_id = ?',
      whereArgs: [id],
      orderBy: 'used_at DESC',
    );
    return rows.map(SubscriptionUsageEventModel.fromMap).toList();
  }

  Future<List<SubscriptionPriceHistoryModel>> getPriceHistory() async {
    final db = await _database.database;
    final rows = await db.query(
      'subscription_price_history',
      orderBy: 'changed_at DESC',
    );
    return rows.map(SubscriptionPriceHistoryModel.fromMap).toList();
  }

  /// Списывает деньги с кошелька, записывает историю и переносит дату следующей оплаты.
  Future<void> markAsPaid(int id) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'subscriptions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('Subscription with id $id was not found.');
      }

      final subscription = SubscriptionModel.fromMap(rows.first);
      final now = DateTime.now();
      final walletRows = await txn.query('wallets', where: 'id = 1', limit: 1);
      final balance = walletRows.first['balance_cents'] as int;
      if (balance < subscription.amountCents) {
        throw StateError('Insufficient funds for subscription payment.');
      }

      await txn.update(
          'wallets',
          {
            'balance_cents': balance - subscription.amountCents,
            'updated_at': now.toIso8601String(),
          },
          where: 'id = 1');
      await txn.insert('transactions', {
        'subscription_id': subscription.id,
        'type': 'charge',
        'amount_cents': subscription.amountCents,
        'currency': subscription.currency,
        'occurred_at': now.toIso8601String(),
        'note': subscription.title,
      });
      await txn.update(
        'subscriptions',
        {
          'next_payment_date':
              _nextPaymentDate(subscription, now).toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Обновляет поле статуса подписки.
  Future<void> _setStatus(
    int id,
    String status, {
    bool clearArchiveAt = false,
  }) async {
    final db = await _database.database;
    await db.update(
      'subscriptions',
      {
        'status': status,
        if (clearArchiveAt) 'archive_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Рассчитывает следующую дату на основе сохранённого периода оплаты.
  static DateTime _nextPaymentDate(
    SubscriptionModel subscription,
    DateTime paidAt,
  ) {
    var next = subscription.nextPaymentDate;
    while (!next.isAfter(paidAt)) {
      next = _advancePaymentDate(next, subscription.billingPeriod);
    }
    return next;
  }

  static DateTime _advancePaymentDate(DateTime current, String billingPeriod) {
    switch (billingPeriod) {
      case 'weekly':
        return current.add(const Duration(days: 7));
      case 'yearly':
        return DateTime(current.year + 1, current.month, current.day);
      case 'monthly':
      default:
        return DateTime(current.year, current.month + 1, current.day);
    }
  }
}
