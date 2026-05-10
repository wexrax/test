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
  static const int databaseVersion = 6;

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
      onUpgrade: _upgradeSchema,
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
      await txn.delete('subscription_usage_events');
      await txn.delete('subscription_price_history');
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
      await txn.delete('subscription_usage_events');
      await txn.delete('subscription_price_history');
      await txn.delete('subscriptions');
      await txn.delete('merchant_subscriptions');
      await txn.update(
          'settings',
          {
            'phone': phone,
            'onboarding_completed': 1,
            'monthly_budget_cents': 220000,
            'hidden_savings_recommendations': '',
            'updated_at': createdAt,
          },
          where: 'id = 1');
      await txn.update(
          'wallets',
          {
            'balance_cents': 1500000,
            'auto_top_up_enabled': 1,
            'auto_top_up_threshold_cents': 300000,
            'auto_top_up_amount_cents': 1000000,
            'updated_at': createdAt,
          },
          where: 'id = 1');

      final subscriptions = [
        _demoSubscription(
          title: 'Netflix',
          category: 'Видео',
          amountCents: 79900,
          billingPeriod: 'monthly',
          nextPaymentDate: now.add(const Duration(days: 3)),
          iconColor: 0xFFE50914,
          createdAt: createdAt,
          lastUsedAt: now.subtract(const Duration(days: 42)),
        ),
        _demoSubscription(
          title: 'Spotify',
          category: 'Музыка',
          amountCents: 29900,
          billingPeriod: 'monthly',
          nextPaymentDate: now.add(const Duration(days: 7)),
          iconColor: 0xFF1DB954,
          createdAt: createdAt,
          trialStartAt: now.subtract(const Duration(days: 5)),
          trialEndAt: now.add(const Duration(days: 9)),
          cancelAfterTrial: true,
          lastUsedAt: now.subtract(const Duration(days: 2)),
        ),
        _demoSubscription(
          title: 'iCloud+',
          category: 'Облако',
          amountCents: 14900,
          billingPeriod: 'monthly',
          nextPaymentDate: now.add(const Duration(days: 12)),
          iconColor: 0xFF147EFB,
          createdAt: createdAt,
          lastUsedAt: now.subtract(const Duration(days: 8)),
        ),
        _demoSubscription(
          title: 'Notion',
          category: 'Работа',
          amountCents: 960000,
          billingPeriod: 'yearly',
          nextPaymentDate: now.add(const Duration(days: 29)),
          iconColor: 0xFF111111,
          createdAt: createdAt,
          lastUsedAt: now.subtract(const Duration(days: 18)),
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
    DateTime? trialStartAt,
    DateTime? trialEndAt,
    bool cancelAfterTrial = false,
    DateTime? lastUsedAt,
  }) {
    return {
      'title': title,
      'category': category,
      'amount_cents': amountCents,
      'currency': 'RUB',
      'billing_period': billingPeriod,
      'next_payment_date': nextPaymentDate.toIso8601String(),
      'status': 'active',
      'trial_start_at': trialStartAt?.toIso8601String(),
      'trial_end_at': trialEndAt?.toIso8601String(),
      'cancel_after_trial': cancelAfterTrial ? 1 : 0,
      'last_used_at': lastUsedAt?.toIso8601String(),
      'inactive_suggestion_hidden_at': null,
      'icon_color': iconColor,
      'description': null,
      'created_at': createdAt,
      'updated_at': createdAt,
    };
  }

  /// Гарантирует наличие дефолтных записей в таблицах с одной строкой.
  static Future<void> _ensureDefaults(DatabaseExecutor db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert(
        'wallets',
        {
          'id': 1,
          'balance_cents': 0,
          'auto_top_up_enabled': 0,
          'auto_top_up_threshold_cents': 0,
          'auto_top_up_amount_cents': 0,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert(
        'settings',
        {
          'id': 1,
          'phone': null,
          'notifications_enabled': 1,
          'notify_7_days': 1,
          'notify_3_days': 1,
          'notify_1_day': 1,
          'face_id_enabled': 0,
          'timezone': 'Europe/Moscow',
          'monthly_budget_cents': null,
          'hidden_savings_recommendations': '',
          'onboarding_completed': 0,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore);
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
        billing_period TEXT NOT NULL CHECK(billing_period IN ('weekly', 'monthly', 'yearly')),
        next_payment_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'archived')),
        archive_at TEXT,
        trial_start_at TEXT,
        trial_end_at TEXT,
        cancel_after_trial INTEGER NOT NULL DEFAULT 0 CHECK(cancel_after_trial IN (0, 1)),
        last_used_at TEXT,
        inactive_suggestion_hidden_at TEXT,
        icon_color INTEGER NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        balance_cents INTEGER NOT NULL DEFAULT 0 CHECK(balance_cents >= 0),
        auto_top_up_enabled INTEGER NOT NULL DEFAULT 0 CHECK(auto_top_up_enabled IN (0, 1)),
        auto_top_up_threshold_cents INTEGER NOT NULL DEFAULT 0 CHECK(auto_top_up_threshold_cents >= 0),
        auto_top_up_amount_cents INTEGER NOT NULL DEFAULT 0 CHECK(auto_top_up_amount_cents >= 0),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subscription_id INTEGER,
        type TEXT NOT NULL CHECK(type IN ('charge', 'top_up')),
        amount_cents INTEGER NOT NULL CHECK(amount_cents >= 0),
        currency TEXT NOT NULL DEFAULT 'RUB',
        occurred_at TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY(subscription_id)
          REFERENCES subscriptions(id)
          ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE subscription_usage_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subscription_id INTEGER NOT NULL,
        used_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(subscription_id)
          REFERENCES subscriptions(id)
          ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE subscription_price_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subscription_id INTEGER,
        subscription_title TEXT NOT NULL,
        old_amount_cents INTEGER NOT NULL CHECK(old_amount_cents >= 0),
        new_amount_cents INTEGER NOT NULL CHECK(new_amount_cents >= 0),
        currency TEXT NOT NULL DEFAULT 'RUB',
        changed_at TEXT NOT NULL,
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
        billing_period TEXT NOT NULL CHECK(billing_period IN ('weekly', 'monthly', 'yearly')),
        subscribers_count INTEGER NOT NULL DEFAULT 0 CHECK(subscribers_count >= 0),
        earned_cents INTEGER NOT NULL DEFAULT 0 CHECK(earned_cents >= 0),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        phone TEXT,
        notifications_enabled INTEGER NOT NULL DEFAULT 1 CHECK(notifications_enabled IN (0, 1)),
        notify_7_days INTEGER NOT NULL DEFAULT 1 CHECK(notify_7_days IN (0, 1)),
        notify_3_days INTEGER NOT NULL DEFAULT 1 CHECK(notify_3_days IN (0, 1)),
        notify_1_day INTEGER NOT NULL DEFAULT 1 CHECK(notify_1_day IN (0, 1)),
        face_id_enabled INTEGER NOT NULL DEFAULT 0 CHECK(face_id_enabled IN (0, 1)),
        timezone TEXT NOT NULL DEFAULT 'Europe/Moscow',
        monthly_budget_cents INTEGER CHECK(monthly_budget_cents IS NULL OR monthly_budget_cents >= 0),
        hidden_savings_recommendations TEXT NOT NULL DEFAULT '',
        onboarding_completed INTEGER NOT NULL DEFAULT 0 CHECK(onboarding_completed IN (0, 1)),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await _createIndexes(db);
  }

  /// Применяет миграции SQLite-схемы между версиями приложения.
  static Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE subscriptions ADD COLUMN archive_at TEXT');
    }
    if (oldVersion < 3) {
      await _rebuildSchemaWithConstraints(db);
    } else {
      if (oldVersion < 4) {
        await db.execute(
          'ALTER TABLE settings ADD COLUMN monthly_budget_cents INTEGER CHECK(monthly_budget_cents IS NULL OR monthly_budget_cents >= 0)',
        );
      }
      if (oldVersion < 5) {
        await db.execute(
          "ALTER TABLE settings ADD COLUMN hidden_savings_recommendations TEXT NOT NULL DEFAULT ''",
        );
      }
      if (oldVersion < 6) {
        await _addAnalyticsSubscriptionColumns(db);
        await _createAnalyticsTables(db);
      }
    }
    await _createIndexes(db);
  }

  static Future<void> _addAnalyticsSubscriptionColumns(
    DatabaseExecutor db,
  ) async {
    await db.execute('ALTER TABLE subscriptions ADD COLUMN trial_start_at TEXT');
    await db.execute('ALTER TABLE subscriptions ADD COLUMN trial_end_at TEXT');
    await db.execute(
      'ALTER TABLE subscriptions ADD COLUMN cancel_after_trial INTEGER NOT NULL DEFAULT 0 CHECK(cancel_after_trial IN (0, 1))',
    );
    await db.execute('ALTER TABLE subscriptions ADD COLUMN last_used_at TEXT');
    await db.execute(
      'ALTER TABLE subscriptions ADD COLUMN inactive_suggestion_hidden_at TEXT',
    );
  }

  static Future<void> _createAnalyticsTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subscription_usage_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subscription_id INTEGER NOT NULL,
        used_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(subscription_id)
          REFERENCES subscriptions(id)
          ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subscription_price_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subscription_id INTEGER,
        subscription_title TEXT NOT NULL,
        old_amount_cents INTEGER NOT NULL CHECK(old_amount_cents >= 0),
        new_amount_cents INTEGER NOT NULL CHECK(new_amount_cents >= 0),
        currency TEXT NOT NULL DEFAULT 'RUB',
        changed_at TEXT NOT NULL,
        FOREIGN KEY(subscription_id)
          REFERENCES subscriptions(id)
          ON DELETE SET NULL
      )
    ''');
  }

  static Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_subscriptions_next_payment ON subscriptions(next_payment_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_subscriptions_archive_at ON subscriptions(archive_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_subscriptions_trial_end ON subscriptions(trial_end_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_subscriptions_last_used ON subscriptions(last_used_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_occurred_at ON transactions(occurred_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_usage_events_subscription ON subscription_usage_events(subscription_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_usage_events_used_at ON subscription_usage_events(used_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_price_history_changed_at ON subscription_price_history(changed_at)',
    );
  }

  static Future<void> _rebuildSchemaWithConstraints(Database db) async {
    await db.execute('PRAGMA foreign_keys = OFF');
    await db.execute('DROP INDEX IF EXISTS idx_subscriptions_status');
    await db.execute('DROP INDEX IF EXISTS idx_subscriptions_next_payment');
    await db.execute('DROP INDEX IF EXISTS idx_subscriptions_archive_at');
    await db.execute('DROP INDEX IF EXISTS idx_subscriptions_trial_end');
    await db.execute('DROP INDEX IF EXISTS idx_subscriptions_last_used');
    await db.execute('DROP INDEX IF EXISTS idx_transactions_occurred_at');
    await db.execute('DROP INDEX IF EXISTS idx_usage_events_subscription');
    await db.execute('DROP INDEX IF EXISTS idx_usage_events_used_at');
    await db.execute('DROP INDEX IF EXISTS idx_price_history_changed_at');

    await db.execute('ALTER TABLE subscriptions RENAME TO subscriptions_old');
    await db.execute('ALTER TABLE wallets RENAME TO wallets_old');
    await db.execute('ALTER TABLE transactions RENAME TO transactions_old');
    await db.execute(
      'ALTER TABLE merchant_subscriptions RENAME TO merchant_subscriptions_old',
    );
    await db.execute('ALTER TABLE settings RENAME TO settings_old');

    await _createSchema(db, databaseVersion);

    await db.execute('''
      INSERT INTO subscriptions (
        id, title, category, amount_cents, currency, billing_period,
        next_payment_date, status, archive_at, trial_start_at, trial_end_at,
        cancel_after_trial, last_used_at, inactive_suggestion_hidden_at,
        icon_color, description, created_at, updated_at
      )
      SELECT
        id,
        title,
        category,
        CASE WHEN amount_cents < 0 THEN 0 ELSE amount_cents END,
        currency,
        CASE
          WHEN billing_period IN ('weekly', 'monthly', 'yearly')
            THEN billing_period
          ELSE 'monthly'
        END,
        next_payment_date,
        CASE WHEN status IN ('active', 'archived') THEN status ELSE 'active' END,
        archive_at,
        NULL,
        NULL,
        0,
        NULL,
        NULL,
        icon_color,
        description,
        created_at,
        updated_at
      FROM subscriptions_old
    ''');
    await db.execute('''
      INSERT INTO wallets (
        id, balance_cents, auto_top_up_enabled, auto_top_up_threshold_cents,
        auto_top_up_amount_cents, created_at, updated_at
      )
      SELECT
        id,
        CASE WHEN balance_cents < 0 THEN 0 ELSE balance_cents END,
        CASE WHEN auto_top_up_enabled = 1 THEN 1 ELSE 0 END,
        CASE
          WHEN auto_top_up_threshold_cents < 0 THEN 0
          ELSE auto_top_up_threshold_cents
        END,
        CASE
          WHEN auto_top_up_amount_cents < 0 THEN 0
          ELSE auto_top_up_amount_cents
        END,
        created_at,
        updated_at
      FROM wallets_old
      WHERE id = 1
    ''');
    await db.execute('''
      INSERT INTO transactions (
        id, subscription_id, type, amount_cents, currency, occurred_at, note
      )
      SELECT
        id,
        subscription_id,
        CASE WHEN type IN ('charge', 'top_up') THEN type ELSE 'charge' END,
        CASE WHEN amount_cents < 0 THEN 0 ELSE amount_cents END,
        currency,
        occurred_at,
        note
      FROM transactions_old
    ''');
    await db.execute('''
      INSERT INTO merchant_subscriptions (
        id, title, description, price_cents, currency, billing_period,
        subscribers_count, earned_cents, created_at, updated_at
      )
      SELECT
        id,
        title,
        description,
        CASE WHEN price_cents < 0 THEN 0 ELSE price_cents END,
        currency,
        CASE
          WHEN billing_period IN ('weekly', 'monthly', 'yearly')
            THEN billing_period
          ELSE 'monthly'
        END,
        CASE WHEN subscribers_count < 0 THEN 0 ELSE subscribers_count END,
        CASE WHEN earned_cents < 0 THEN 0 ELSE earned_cents END,
        created_at,
        updated_at
      FROM merchant_subscriptions_old
    ''');
    await db.execute('''
      INSERT INTO settings (
        id, phone, notifications_enabled, notify_7_days, notify_3_days,
        notify_1_day, face_id_enabled, timezone, onboarding_completed,
        created_at, updated_at
      )
      SELECT
        id,
        phone,
        CASE WHEN notifications_enabled = 0 THEN 0 ELSE 1 END,
        CASE WHEN notify_7_days = 0 THEN 0 ELSE 1 END,
        CASE WHEN notify_3_days = 0 THEN 0 ELSE 1 END,
        CASE WHEN notify_1_day = 0 THEN 0 ELSE 1 END,
        CASE WHEN face_id_enabled = 1 THEN 1 ELSE 0 END,
        timezone,
        CASE WHEN onboarding_completed = 1 THEN 1 ELSE 0 END,
        created_at,
        updated_at
      FROM settings_old
      WHERE id = 1
    ''');

    await db.execute('DROP TABLE subscriptions_old');
    await db.execute('DROP TABLE wallets_old');
    await db.execute('DROP TABLE transactions_old');
    await db.execute('DROP TABLE merchant_subscriptions_old');
    await db.execute('DROP TABLE settings_old');
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Архивирует активные подписки с истёкшим таймером автоархивации.
  Future<int> archiveDueSubscriptions(DateTime now) async {
    final db = await database;
    return db.update(
      'subscriptions',
      {
        'status': 'archived',
        'archive_at': null,
        'updated_at': now.toIso8601String(),
      },
      where: 'status = ? AND archive_at IS NOT NULL AND archive_at <= ?',
      whereArgs: ['active', now.toIso8601String()],
    );
  }

  /// Архивирует активные подписки, у которых завершился триал с автоотменой.
  Future<int> cancelDueTrials(DateTime now) async {
    final db = await database;
    return db.update(
      'subscriptions',
      {
        'status': 'archived',
        'archive_at': null,
        'cancel_after_trial': 0,
        'updated_at': now.toIso8601String(),
      },
      where: '''
        status = ?
        AND cancel_after_trial = 1
        AND trial_end_at IS NOT NULL
        AND trial_end_at <= ?
      ''',
      whereArgs: ['active', now.toIso8601String()],
    );
  }
}
