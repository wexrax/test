import '../models/merchant_subscription_model.dart';
import 'app_database.dart';

/// Выполняет SQLite-запросы и изменения для мерчант-подписок.
class MerchantSubscriptionDao {
  const MerchantSubscriptionDao(this._database);

  final AppDatabase _database;

  /// Добавляет мерчант-подписку и возвращает её сгенерированный идентификатор.
  Future<int> create(MerchantSubscriptionModel subscription) async {
    final db = await _database.database;
    final values = subscription.toMap()..remove('id');
    return db.insert('merchant_subscriptions', values);
  }

  /// Загружает все мерчант-подписки, начиная с новых.
  Future<List<MerchantSubscriptionModel>> getAll() async {
    final db = await _database.database;
    final rows = await db.query(
      'merchant_subscriptions',
      orderBy: 'created_at DESC',
    );
    return rows.map(MerchantSubscriptionModel.fromMap).toList();
  }

  /// Обновляет существующую мерчант-подписку.
  Future<void> update(MerchantSubscriptionModel subscription) async {
    final id = subscription.id;
    if (id == null) {
      throw ArgumentError('Merchant subscription id is required for update.');
    }

    final db = await _database.database;
    await db.update(
      'merchant_subscriptions',
      subscription.toMap()
        ..remove('id')
        ..remove('created_at')
        ..['updated_at'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Удаляет мерчант-подписку по идентификатору.
  Future<void> delete(int id) async {
    final db = await _database.database;
    await db.delete('merchant_subscriptions', where: 'id = ?', whereArgs: [id]);
  }

  /// Выводит заработок, если достигнута минимальная сумма.
  Future<int> withdraw(int id) async {
    final db = await _database.database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'merchant_subscriptions',
        columns: ['earned_cents'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('Merchant subscription with id $id was not found.');
      }

      final earnedCents = rows.first['earned_cents'] as int;
      if (earnedCents < 10000) {
        return 0;
      }

      await txn.update(
        'merchant_subscriptions',
        {'earned_cents': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      return earnedCents;
    });
  }
}
