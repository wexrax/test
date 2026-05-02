import '../models/subscription_model.dart';
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
    final values = subscription.copyWith(updatedAt: DateTime.now()).toMap()
      ..remove('id')
      ..remove('created_at');
    await db.update(
      'subscriptions',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Переносит подписку из активного списка без удаления истории.
  Future<void> archive(int id) async {
    await _setStatus(id, 'archived');
  }

  /// Возвращает архивную подписку в активный список.
  Future<void> restore(int id) async {
    await _setStatus(id, 'active');
  }

  /// Удаляет подписку, сохраняя строки транзакций.
  Future<void> delete(int id) async {
    final db = await _database.database;
    await db.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
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
          'next_payment_date': _nextPaymentDate(subscription).toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Обновляет поле статуса подписки.
  Future<void> _setStatus(int id, String status) async {
    final db = await _database.database;
    await db.update(
      'subscriptions',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Рассчитывает следующую дату на основе сохранённого периода оплаты.
  static DateTime _nextPaymentDate(SubscriptionModel subscription) {
    final current = subscription.nextPaymentDate;
    switch (subscription.billingPeriod) {
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
