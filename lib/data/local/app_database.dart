import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Управляет открытием, инициализацией, заполнением и очисткой локальной SQLite-базы.
class AppDatabase {
  AppDatabase._();

  /// Общий экземпляр базы, который используют DAO и репозитории.
  static final AppDatabase instance = AppDatabase._();

  /// Имя файла локальной SQLite-базы.
  static const String databaseName = 'subsflow.db';

  /// Версия схемы для миграций sqflite.
  static const int databaseVersion = 1;

  Database? _database;

  /// Возвращает открытую базу, создавая схему и дефолтные записи при первом доступе.
  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, databaseName);

    final opened = await openDatabase(
      dbPath,
      version: databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createSchema,
      onOpen: _ensureDefaults,
    );

    _database = opened;
    return opened;
  }

  /// Закрывает активное подключение к базе.
  Future<void> close() async {
    final db = _database;
    if (db == null) {
      return;
    }

    await db.close();
    _database = null;
  }

  /// Удаляет все пользовательские данные и создаёт обязательные одиночные записи заново.
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('subscriptions');
      await txn.delete('merchant_subscriptions');
      await txn.delete('wallets');
      await txn.delete('settings');
    });
    await _ensureDefaults(db);
  }

  /// Заменяет текущие данные демо-контентом для сценария входа в прототип.
  Future<void> seedDemoData({String? phone}) async {
    final db = await database;
    final now = DateTime.now();
    final createdAt = now.toIso8601String();

    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('subscriptions');
      await txn.delete('merchant_subscriptions');
      await txn.update('settings', {
        'phone': phone,
        'onboarding_completed': 1,
        'updated_at': createdAt,
      }, where: 'id = 1');
      await txn.update('wallets', {
        'balance_cents': 1500000,
        'auto_top_up_enabled': 1,
        'auto_top_up_threshold_cents': 300000,
        'auto_top_up_amount_cents': 1000000,
        'updated_at': createdAt,
      }, where: 'id = 1');

      final subscriptions = [
        _demoSubscription(
          title: 'Netflix',
          category: 'Видео',
          amountCents: 79900,
          billingPeriod: 'monthly',
          nextPaymentDate: now.add(const Duration(days: 3)),
          iconColor: 0xFFE50914,
          createdAt: createdAt,
        ),
        _demoSubscription(
          title: 'Spotify',
          category: 'Музыка',
          amountCents: 29900,
          billingPeriod: 'monthly',
          nextPaymentDate: now.add(const Duration(days: 7)),
          iconColor: 0xFF1DB954,
          createdAt: createdAt,
        ),
        _demoSubscription(
          title: 'iCloud+',
          category: 'Облако',
          amountCents: 14900,
          billingPeriod: 'monthly',
          nextPaymentDate: now.add(const Duration(days: 12)),
          iconColor: 0xFF147EFB,
          createdAt: createdAt,
        ),
        _demoSubscription(
          title: 'Notion',
          category: 'Работа',
          amountCents: 960000,
          billingPeriod: 'yearly',
          nextPaymentDate: now.add(const Duration(days: 29)),
          iconColor: 0xFF111111,
          createdAt: createdAt,
        ),
      ];

      for (final subscription in subscriptions) {
        await txn.insert('subscriptions', subscription);
      }

      await txn.insert('merchant_subscriptions', {
        'title': 'Закрытый канал',
        'description': 'Ежемесячная подписка на авторский контент',
        'price_cents': 49000,
        'currency': 'RUB',
        'billing_period': 'monthly',
        'subscribers_count': 8,
        'earned_cents': 392000,
        'created_at': createdAt,
        'updated_at': createdAt,
      });
    });
  }

  /// Создаёт строку демо-подписки без обращения к базе.
  static Map<String, Object?> _demoSubscription({
    required String title,
    required String category,
    required int amountCents,
    required String billingPeriod,
    required DateTime nextPaymentDate,
    required int iconColor,
    required String createdAt,
  }) {
    return {
      'title': title,
      'category': category,
      'amount_cents': amountCents,
      'currency': 'RUB',
      'billing_period': billingPeriod,
      'next_payment_date': nextPaymentDate.toIso8601String(),
      'status': 'active',
      'icon_color': iconColor,
      'description': null,
      'created_at': createdAt,
      'updated_at': createdAt,
    };
  }

  /// Гарантирует наличие дефолтных записей в таблицах с одной строкой.
  static Future<void> _ensureDefaults(DatabaseExecutor db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert('wallets', {
      'id': 1,
      'balance_cents': 0,
      'auto_top_up_enabled': 0,
      'auto_top_up_threshold_cents': 0,
      'auto_top_up_amount_cents': 0,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('settings', {
      'id': 1,
      'phone': null,
      'notifications_enabled': 1,
      'notify_7_days': 1,
      'notify_3_days': 1,
      'notify_1_day': 1,
      'face_id_enabled': 0,
      'timezone': 'Europe/Moscow',
      'onboarding_completed': 0,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Создаёт начальную версию SQLite-схемы.
  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        amount_cents INTEGER NOT NULL CHECK(amount_cents >= 0),
        currency TEXT NOT NULL DEFAULT 'RUB',
        billing_period TEXT NOT NULL,
        next_payment_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        icon_color INTEGER NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        balance_cents INTEGER NOT NULL DEFAULT 0,
        auto_top_up_enabled INTEGER NOT NULL DEFAULT 0,
        auto_top_up_threshold_cents INTEGER NOT NULL DEFAULT 0,
        auto_top_up_amount_cents INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subscription_id INTEGER,
        type TEXT NOT NULL,
        amount_cents INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'RUB',
        occurred_at TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY(subscription_id)
          REFERENCES subscriptions(id)
          ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE merchant_subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        price_cents INTEGER NOT NULL CHECK(price_cents >= 0),
        currency TEXT NOT NULL DEFAULT 'RUB',
        billing_period TEXT NOT NULL,
        subscribers_count INTEGER NOT NULL DEFAULT 0,
        earned_cents INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        phone TEXT,
        notifications_enabled INTEGER NOT NULL DEFAULT 1,
        notify_7_days INTEGER NOT NULL DEFAULT 1,
        notify_3_days INTEGER NOT NULL DEFAULT 1,
        notify_1_day INTEGER NOT NULL DEFAULT 1,
        face_id_enabled INTEGER NOT NULL DEFAULT 0,
        timezone TEXT NOT NULL DEFAULT 'Europe/Moscow',
        onboarding_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_subscriptions_status ON subscriptions(status)',
    );
    await db.execute(
      'CREATE INDEX idx_subscriptions_next_payment ON subscriptions(next_payment_date)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_occurred_at ON transactions(occurred_at)',
    );
  }
}
