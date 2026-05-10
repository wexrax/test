import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:my_subscriptions_frontend/core/utils/export_utils.dart';
import 'package:my_subscriptions_frontend/data/local/app_database.dart';
import 'package:my_subscriptions_frontend/data/local/merchant_subscription_dao.dart';
import 'package:my_subscriptions_frontend/data/local/settings_dao.dart';
import 'package:my_subscriptions_frontend/data/local/subscription_dao.dart';
import 'package:my_subscriptions_frontend/data/local/transaction_dao.dart';
import 'package:my_subscriptions_frontend/data/local/wallet_dao.dart';
import 'package:my_subscriptions_frontend/data/models/merchant_subscription_model.dart';
import 'package:my_subscriptions_frontend/data/models/subscription_model.dart';
import 'package:my_subscriptions_frontend/data/models/transaction_model.dart';
import 'package:my_subscriptions_frontend/data/repositories/transaction_repository_impl.dart';
import 'package:my_subscriptions_frontend/data/repositories/wallet_repository_impl.dart';
import 'package:my_subscriptions_frontend/core/services/notification_service.dart';
import 'package:my_subscriptions_frontend/presentation/providers/reminder_provider.dart';
import 'package:my_subscriptions_frontend/presentation/providers/analytics_provider.dart';
import 'package:my_subscriptions_frontend/presentation/providers/repository_providers.dart';
import 'package:my_subscriptions_frontend/presentation/providers/subscription_provider.dart';
import 'package:my_subscriptions_frontend/presentation/providers/wallet_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = AppDatabase.instance;
    await database.close();
    final databasePath = p.join(
      await getDatabasesPath(),
      AppDatabase.databaseName,
    );
    await databaseFactory.deleteDatabase(databasePath);
    await database.clearAllData();
  });

  tearDown(() async {
    await database.close();
  });

  test('subscription backend persists custom user subscriptions', () async {
    final subscriptionDao = SubscriptionDao(database);
    final now = DateTime.now();

    final id = await subscriptionDao.create(
      SubscriptionModel(
        title: 'Telegram Premium',
        category: 'Связь',
        amountCents: 29900,
        billingPeriod: 'weekly',
        nextPaymentDate: now.add(const Duration(days: 7)),
        iconColor: 0xFFFFD54F,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final saved = await subscriptionDao.getById(id);

    expect(saved, isNotNull);
    expect(saved!.title, 'Telegram Premium');
    expect(saved.category, 'Связь');
    expect(saved.amountCents, 29900);
    expect(saved.billingPeriod, 'weekly');
    expect(saved.status, 'active');
  });

  test('markAsPaid advances overdue monthly subscription into the future',
      () async {
    final walletDao = WalletDao(database);
    final subscriptionDao = SubscriptionDao(database);
    final now = DateTime.now();

    await walletDao.topUp(1000000);
    final id = await subscriptionDao.create(
      SubscriptionModel(
        title: 'Overdue service',
        category: 'Work',
        amountCents: 10000,
        billingPeriod: 'monthly',
        nextPaymentDate: DateTime(now.year, now.month - 4, now.day),
        iconColor: 0xFF111111,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await subscriptionDao.markAsPaid(id);

    final updated = await subscriptionDao.getById(id);
    expect(updated, isNotNull);
    expect(updated!.nextPaymentDate.isAfter(now), isTrue);

    final transactions = await TransactionDao(database).getRecent();
    expect(transactions.where((t) => t.type == 'charge'), hasLength(1));
  });

  test('wallet load does not apply auto top up, startup reconcile does',
      () async {
    final walletDao = WalletDao(database);
    await walletDao.configureAutoTopUp(
      enabled: true,
      thresholdCents: 100000,
      amountCents: 10000,
    );

    final notifier = WalletNotifier(
      WalletRepositoryImpl(walletDao),
      TransactionRepositoryImpl(TransactionDao(database)),
    );

    await notifier.load();
    expect(notifier.state.balance, 0);
    expect(notifier.state.transactions, isEmpty);

    await notifier.applyStartupAutoTopUp();
    expect(notifier.state.balance, 100);
    expect(notifier.state.transactions, hasLength(1));
  });

  test('settings persist analytics preferences', () async {
    final dao = SettingsDao(database);

    await dao.updateMonthlyBudget(monthlyBudgetCents: 250000);
    await dao.updateHiddenSavingsRecommendations('1:Anytype');
    final withBudget = await dao.getSettings();
    expect(withBudget.monthlyBudgetCents, 250000);
    expect(withBudget.hiddenSavingsRecommendations, '1:Anytype');

    await dao.updateMonthlyBudget(monthlyBudgetCents: null);
    final withoutBudget = await dao.getSettings();
    expect(withoutBudget.monthlyBudgetCents, isNull);
  });

  test('due trial auto cancel archives without wallet transaction', () async {
    final subscriptionDao = SubscriptionDao(database);
    final now = DateTime.now();
    final id = await subscriptionDao.create(
      SubscriptionModel(
        title: 'Trial service',
        category: 'Tools',
        amountCents: 50000,
        billingPeriod: 'monthly',
        nextPaymentDate: now.add(const Duration(days: 1)),
        trialStartAt: now.subtract(const Duration(days: 14)),
        trialEndAt: now.subtract(const Duration(days: 1)),
        cancelAfterTrial: true,
        iconColor: 0xFF111111,
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(days: 14)),
      ),
    );

    final count = await subscriptionDao.cancelDueTrials(now);
    final updated = await subscriptionDao.getById(id);
    final transactions = await TransactionDao(database).getRecent();

    expect(count, 1);
    expect(updated!.status, 'archived');
    expect(updated.cancelAfterTrial, isFalse);
    expect(transactions, isEmpty);
  });

  test('markUsed writes usage event and refreshes lastUsedAt', () async {
    final subscriptionDao = SubscriptionDao(database);
    final now = DateTime.now();
    final usedAt = DateTime(2026, 5, 1, 12);
    final id = await subscriptionDao.create(
      SubscriptionModel(
        title: 'Usage service',
        category: 'Tools',
        amountCents: 10000,
        billingPeriod: 'monthly',
        nextPaymentDate: now.add(const Duration(days: 10)),
        inactiveSuggestionHiddenAt: now,
        iconColor: 0xFF111111,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await subscriptionDao.markUsed(id, usedAt: usedAt);

    final updated = await subscriptionDao.getById(id);
    final events = await subscriptionDao.getUsageEvents(id);
    expect(updated!.lastUsedAt, usedAt);
    expect(updated.inactiveSuggestionHiddenAt, isNull);
    expect(events, hasLength(1));
    expect(events.single.usedAt, usedAt);
  });

  test('subscription update records price history only on amount change',
      () async {
    final subscriptionDao = SubscriptionDao(database);
    final now = DateTime.now();
    final id = await subscriptionDao.create(
      SubscriptionModel(
        title: 'Price service',
        category: 'Tools',
        amountCents: 10000,
        billingPeriod: 'monthly',
        nextPaymentDate: now.add(const Duration(days: 10)),
        iconColor: 0xFF111111,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final created = (await subscriptionDao.getById(id))!;

    await subscriptionDao.update(created.copyWith(amountCents: 15000));
    await subscriptionDao.update(
      (await subscriptionDao.getById(id))!.copyWith(title: 'Price renamed'),
    );

    final history = await subscriptionDao.getPriceHistory();
    expect(history, hasLength(1));
    expect(history.single.oldAmountCents, 10000);
    expect(history.single.newAmountCents, 15000);
    expect(history.single.subscriptionTitle, 'Price service');
  });

  test('merchant update preserves createdAt', () async {
    final dao = MerchantSubscriptionDao(database);
    final createdAt = DateTime(2024, 1, 2, 3, 4, 5);
    final id = await dao.create(
      MerchantSubscriptionModel(
        title: 'Original',
        description: 'Before',
        priceCents: 10000,
        billingPeriod: 'monthly',
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );

    await dao.update(
      MerchantSubscriptionModel(
        id: id,
        title: 'Updated',
        description: 'After',
        priceCents: 20000,
        billingPeriod: 'monthly',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );

    final updated = (await dao.getAll()).single;
    expect(updated.title, 'Updated');
    expect(updated.createdAt, createdAt);
  });

  test('archive timer moves due active subscription to archive', () async {
    final dao = SubscriptionDao(database);
    final now = DateTime.now();
    final id = await dao.create(
      SubscriptionModel(
        title: 'Timer archive',
        category: 'Tools',
        amountCents: 5000,
        billingPeriod: 'monthly',
        nextPaymentDate: now.add(const Duration(days: 10)),
        iconColor: 0xFF222222,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await dao.scheduleArchive(id, now.subtract(const Duration(minutes: 1)));
    final archivedCount = await dao.archiveDueSubscriptions(now);

    final archived = await dao.getById(id);
    expect(archivedCount, 1);
    expect(archived, isNotNull);
    expect(archived!.isActive, isFalse);
    expect(archived.archiveAt, isNull);
  });

  test('archive timer ignores future subscription until due', () async {
    final dao = SubscriptionDao(database);
    final now = DateTime.now();
    final id = await dao.create(
      SubscriptionModel(
        title: 'Future archive',
        category: 'Tools',
        amountCents: 5000,
        billingPeriod: 'monthly',
        nextPaymentDate: now.add(const Duration(days: 10)),
        iconColor: 0xFF222222,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await dao.scheduleArchive(id, now.add(const Duration(days: 1)));
    final archivedCount = await dao.archiveDueSubscriptions(now);

    final active = await dao.getById(id);
    expect(archivedCount, 0);
    expect(active, isNotNull);
    expect(active!.isActive, isTrue);
    expect(active.archiveAt, isNotNull);
  });

  test('archived subscriptions appear in archived query', () async {
    final dao = SubscriptionDao(database);
    final now = DateTime.now();
    final id = await dao.create(
      SubscriptionModel(
        title: 'Manual archive',
        category: 'Tools',
        amountCents: 5000,
        billingPeriod: 'monthly',
        nextPaymentDate: now.add(const Duration(days: 10)),
        iconColor: 0xFF222222,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await dao.archive(id);

    final active = await dao.getAll(status: 'active');
    final archived = await dao.getAll(status: 'archived');
    expect(active.where((s) => s.id == id), isEmpty);
    expect(archived.where((s) => s.id == id), hasLength(1));
  });

  test('pending archive subscriptions are hidden from active collections', () {
    final now = DateTime.now();
    final active = _subscriptionData(
      id: 1,
      name: 'Active',
      amount: 100,
      nextPaymentDate: now.add(const Duration(days: 3)),
    );
    final pendingArchive = _subscriptionData(
      id: 2,
      name: 'Pending',
      amount: 200,
      nextPaymentDate: now.add(const Duration(days: 1)),
      archiveAt: now.add(const Duration(days: 2)),
    );
    final archived = _subscriptionData(
      id: 3,
      name: 'Archived',
      amount: 300,
      nextPaymentDate: now.add(const Duration(days: 2)),
      isActive: false,
    );

    final subscriptions = [active, pendingArchive, archived];

    expect(visibleActiveSubscriptions(subscriptions), [active]);
    expect(
      archiveSystemSubscriptions(subscriptions),
      [pendingArchive, archived],
    );
  });

  test('dashboard derived calculations ignore pending archive subscriptions',
      () {
    final now = DateTime.now();
    final active = _subscriptionData(
      id: 1,
      name: 'Active',
      amount: 120,
      category: 'Work',
      nextPaymentDate: now.add(const Duration(days: 5)),
    );
    final pendingArchive = _subscriptionData(
      id: 2,
      name: 'Pending',
      amount: 999,
      category: 'Hidden',
      nextPaymentDate: now.add(const Duration(days: 1)),
      archiveAt: now.add(const Duration(days: 2)),
    );

    final visibleActive = visibleActiveSubscriptions([active, pendingArchive]);
    final sortedUpcoming = [...visibleActive]
      ..sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
    final categoryBreakdown = <String, double>{};
    for (final subscription in visibleActive) {
      categoryBreakdown.update(
        subscription.category,
        (value) => value + subscription.amount,
        ifAbsent: () => subscription.amount,
      );
    }

    expect(visibleActive, [active]);
    expect(
      visibleActive.fold<double>(
        0,
        (sum, subscription) => sum + subscription.amount,
      ),
      120,
    );
    expect(
      visibleActive.fold<double>(
        0,
        (sum, subscription) => sum + subscription.amount * 12,
      ),
      1440,
    );
    expect(sortedUpcoming.take(4), [active]);
    expect(categoryBreakdown, {'Work': 120});
  });

  test('analytics uses current plan as monthly KPI', () {
    final now = DateTime(2026, 5, 7);
    final subscription = _subscriptionData(
      id: 1,
      name: 'Netflix',
      amount: 799,
      category: 'Video',
      nextPaymentDate: DateTime(2026, 5, 10),
    );

    final snapshot = AnalyticsSnapshot.build(
      activeSubscriptions: [subscription],
      transactions: const [],
      settings: const {'monthly_budget': ''},
      now: now,
    );

    expect(snapshot.actualMonthSpent, 799);
    expect(snapshot.plannedMonthlyCost, 799);
    expect(snapshot.actualAverageCheck, 799);
    expect(snapshot.hasCurrentMonthCharges, isTrue);
    expect(snapshot.hasTransactionHistory, isTrue);
    expect(snapshot.yearlyForecast, 9588);
    expect(snapshot.months.last.amount, 799);
    expect(snapshot.months.last.subscriptions.single.name, 'Netflix');
    expect(snapshot.categories.single.amount, 799);
    expect(snapshot.upcomingPayments, [subscription]);
    expect(snapshot.recommendations, isNotEmpty);
    expect(snapshot.potentialSavings, greaterThan(0));
  });

  test('analytics current month facts use only charge transactions', () {
    final now = DateTime(2026, 5, 7);
    final subscription = _subscriptionData(
      id: 1,
      name: 'iCloud+',
      amount: 149,
      nextPaymentDate: DateTime(2026, 5, 10),
    );
    final transactions = [
      TransactionData(
        id: 1,
        type: 'payment',
        amount: 149,
        date: DateTime(2026, 5, 2),
        description: 'iCloud+',
        subscriptionId: 1,
      ),
      TransactionData(
        id: 2,
        type: 'charge',
        amount: 299,
        date: DateTime(2026, 5, 3),
        description: 'Music',
        subscriptionId: 2,
      ),
      TransactionData(
        id: 3,
        type: 'topup',
        amount: 1000,
        date: DateTime(2026, 5, 4),
        description: 'Top up',
      ),
    ];

    final snapshot = AnalyticsSnapshot.build(
      activeSubscriptions: [subscription],
      transactions: transactions,
      settings: const {'monthly_budget': ''},
      now: now,
    );

    expect(snapshot.actualMonthSpent, 149);
    expect(snapshot.actualAverageCheck, 149);
    expect(snapshot.hasCurrentMonthCharges, isTrue);
    expect(snapshot.plannedMonthlyCost, 149);
    expect(snapshot.months.last.amount, 149);
  });

  test('analytics history reflects only real monthly charge sums', () {
    final now = DateTime(2026, 5, 7);
    final subscription = _subscriptionData(
      id: 1,
      name: 'iCloud+',
      amount: 149,
      nextPaymentDate: DateTime(2026, 5, 10),
    );
    final transactions = [
      TransactionData(
        id: 1,
        type: 'payment',
        amount: 149,
        date: DateTime(2026, 4, 10),
        description: 'iCloud+',
        subscriptionId: 1,
      ),
      TransactionData(
        id: 2,
        type: 'charge',
        amount: 299,
        date: DateTime(2026, 3, 10),
        description: 'Music',
        subscriptionId: 2,
      ),
      TransactionData(
        id: 3,
        type: 'topup',
        amount: 1000,
        date: DateTime(2026, 4, 11),
        description: 'Top up',
      ),
    ];

    final snapshot = AnalyticsSnapshot.build(
      activeSubscriptions: [subscription],
      transactions: transactions,
      settings: const {'monthly_budget': ''},
      now: now,
    );

    expect(snapshot.actualMonthSpent, 149);
    expect(snapshot.previousActualMonthSpent, 149);
    expect(snapshot.hasPreviousActualMonthSpent, isTrue);
    expect(snapshot.hasTransactionHistory, isTrue);
    expect(snapshot.months[snapshot.months.length - 3].amount, 299);
    expect(snapshot.months[snapshot.months.length - 2].amount, 149);
    expect(snapshot.months.last.amount, 149);
  });

  test('analytics savings are hidden and budget uses planned subscriptions',
      () {
    final now = DateTime(2026, 5, 7);
    final subscription = _subscriptionData(
      id: 1,
      name: 'iCloud+',
      amount: 149,
      nextPaymentDate: DateTime(2026, 5, 10),
    );

    final snapshot = AnalyticsSnapshot.build(
      activeSubscriptions: [subscription],
      transactions: const [],
      settings: const {
        'monthly_budget': '100',
        'hidden_savings_recommendations': '1:Облако Mail.ru',
      },
      now: now,
    );

    expect(snapshot.recommendations, isEmpty);
    expect(snapshot.potentialSavings, 0);
    expect(snapshot.actualMonthSpent, 149);
    expect(snapshot.plannedMonthlyCost, 149);
    expect(snapshot.isBudgetExceeded, isTrue);
    expect(snapshot.budgetOverrun, 49);
    expect(snapshot.budgetProgress, 1);
  });

  test(
      'analytics exposes category trend, inactive rows and top recommendations',
      () {
    final now = DateTime(2026, 5, 7);
    final netflix = _subscriptionData(
      id: 1,
      name: 'Netflix',
      amount: 799,
      category: 'Видео',
      nextPaymentDate: DateTime(2026, 5, 10),
      lastUsedAt: DateTime(2026, 3, 1),
    );
    final spotify = _subscriptionData(
      id: 2,
      name: 'Spotify',
      amount: 299,
      category: 'Музыка',
      nextPaymentDate: DateTime(2026, 5, 12),
      lastUsedAt: DateTime(2026, 5, 1),
    );
    final hiddenInactive = _subscriptionData(
      id: 3,
      name: 'Dropbox Plus',
      amount: 999,
      category: 'Облако',
      nextPaymentDate: DateTime(2026, 5, 14),
      lastUsedAt: DateTime(2026, 3, 1),
      inactiveSuggestionHiddenAt: DateTime(2026, 4, 1),
    );
    final transactions = [
      TransactionData(
        id: 1,
        type: 'charge',
        amount: 399,
        date: DateTime(2026, 4, 3),
        description: 'Netflix',
        subscriptionId: 1,
      ),
    ];

    final snapshot = AnalyticsSnapshot.build(
      activeSubscriptions: [netflix, spotify, hiddenInactive],
      transactions: transactions,
      settings: const {
        'monthly_budget': '',
        'hidden_savings_recommendations': '2:VK Музыка',
      },
      now: now,
    );

    final video = snapshot.categories.firstWhere((row) => row.name == 'Видео');
    expect(video.percent.round(), 38);
    expect(video.changePercent, 100);
    expect(snapshot.inactiveSubscriptions, hasLength(1));
    expect(snapshot.inactiveSubscriptions.single.subscription.name, 'Netflix');
    expect(snapshot.recommendations, hasLength(3));
    expect(
      snapshot.recommendations.map((item) => item.annualSavings).toList(),
      orderedEquals(
        snapshot.recommendations.map((item) => item.annualSavings).toList()
          ..sort((a, b) => b.compareTo(a)),
      ),
    );
    expect(
      snapshot.recommendations.any((item) => item.key == '2:VK Музыка'),
      isFalse,
    );
  });

  test('disabled notification toggles produce empty reminder schedule', () {
    final now = DateTime(2026, 5, 7, 8);
    final subscription = _subscriptionData(
      id: 1,
      name: 'Active',
      amount: 100,
      nextPaymentDate: DateTime(2026, 5, 14),
    );

    final reminders = buildSubscriptionReminders(
      settings: _notificationSettings(days7: false, days3: false, days1: false),
      subscriptions: [subscription],
      now: now,
    );

    expect(reminders, isEmpty);
    expect(
      countScheduledSubscriptionReminders(
        settings: _notificationSettings(
          days7: false,
          days3: false,
          days1: false,
        ),
        subscriptions: [subscription],
        now: now,
      ),
      0,
    );
  });

  test('pending archive subscriptions do not enter payment reminders', () {
    final now = DateTime(2026, 5, 7, 8);
    final active = _subscriptionData(
      id: 1,
      name: 'Active',
      amount: 100,
      nextPaymentDate: DateTime(2026, 5, 14),
    );
    final pendingArchive = _subscriptionData(
      id: 2,
      name: 'Pending archive',
      amount: 100,
      nextPaymentDate: DateTime(2026, 5, 14),
      archiveAt: DateTime(2026, 5, 8),
    );

    final reminders = buildSubscriptionReminders(
      settings: _notificationSettings(),
      subscriptions: [active, pendingArchive],
      now: now,
    );

    expect(reminders.map((reminder) => reminder.subscription.id), [1]);
  });

  test('active subscription due in 7, 3 and 1 days enters reminders', () {
    final now = DateTime(2026, 5, 7, 8);
    final subscriptions = [
      _subscriptionData(
        id: 1,
        name: 'Seven',
        amount: 100,
        nextPaymentDate: DateTime(2026, 5, 14),
      ),
      _subscriptionData(
        id: 2,
        name: 'Three',
        amount: 100,
        nextPaymentDate: DateTime(2026, 5, 10),
      ),
      _subscriptionData(
        id: 3,
        name: 'One',
        amount: 100,
        nextPaymentDate: DateTime(2026, 5, 8),
      ),
    ];

    final reminders = buildSubscriptionReminders(
      settings: _notificationSettings(),
      subscriptions: subscriptions,
      now: now,
    );

    expect(reminders.map((reminder) => reminder.daysUntilPayment), [1, 3, 7]);
    expect(
      countScheduledSubscriptionReminders(
        settings: _notificationSettings(),
        subscriptions: subscriptions,
        now: now,
      ),
      6,
    );
  });

  test('notification service helper maps permission and managed payloads', () {
    expect(
      permissionStateFromEnabled(true),
      NotificationPermissionState.granted,
    );
    expect(
      permissionStateFromEnabled(false),
      NotificationPermissionState.denied,
    );
    expect(
      permissionStateFromEnabled(null),
      NotificationPermissionState.unknown,
    );
    expect(isManagedNotificationPayload('subscription:1'), isTrue);
    expect(isManagedNotificationPayload('archive:1'), isTrue);
    expect(isManagedNotificationPayload('test:notification'), isTrue);
    expect(isManagedNotificationPayload('other:1'), isFalse);
  });

  test('subscriptions CSV contains all rows and statuses', () {
    final csv = buildSubscriptionsCsv([
      SubscriptionCsvRow(
        name: 'Netflix',
        category: 'Video',
        amount: 799,
        period: 'monthly',
        nextPaymentDate: DateTime(2026, 5, 10),
        status: 'active',
      ),
      SubscriptionCsvRow(
        name: 'Archive item',
        category: 'Cloud',
        amount: 149,
        period: 'yearly',
        nextPaymentDate: DateTime(2026, 6, 1),
        status: 'archived',
      ),
    ]);

    expect(csv, contains('Netflix'));
    expect(csv, contains('Archive item'));
    expect(csv, contains('active'));
    expect(csv, contains('archived'));
  });

  test('history provider returns all transactions in selected period',
      () async {
    final transactionDao = TransactionDao(database);
    final now = DateTime.now();
    for (var i = 0; i < 60; i++) {
      await transactionDao.create(
        TransactionModel(
          type: 'charge',
          amountCents: 100 + i,
          occurredAt: now.subtract(Duration(minutes: i)),
          note: 'Payment $i',
        ),
      );
    }

    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(
          TransactionRepositoryImpl(transactionDao),
        ),
      ],
    );
    addTearDown(container.dispose);

    final transactions = await container.read(
      filteredTransactionsProvider('month').future,
    );

    expect(transactions, hasLength(60));
    expect(transactions.every((t) => t.type == 'payment'), isTrue);
  });

  test('database rejects invalid domain values', () async {
    final db = await database.database;
    final now = DateTime.now().toIso8601String();

    await expectLater(
      db.insert('subscriptions', {
        'title': 'Invalid',
        'category': 'Bad data',
        'amount_cents': 1000,
        'currency': 'RUB',
        'billing_period': 'daily',
        'next_payment_date': now,
        'status': 'active',
        'icon_color': 0xFF000000,
        'created_at': now,
        'updated_at': now,
      }),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      db.insert('transactions', {
        'type': 'refund',
        'amount_cents': 1000,
        'currency': 'RUB',
        'occurred_at': now,
      }),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      db.update(
        'wallets',
        {'auto_top_up_threshold_cents': -1},
        where: 'id = 1',
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('database migrates version 5 analytics fields and tables', () async {
    await database.close();
    final databasePath = p.join(
      await getDatabasesPath(),
      AppDatabase.databaseName,
    );
    await databaseFactory.deleteDatabase(databasePath);

    final legacyDb = await databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 5,
        onCreate: (db, _) async {
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
        },
      ),
    );
    final now = DateTime.now().toIso8601String();
    await legacyDb.insert('subscriptions', {
      'title': 'Legacy v5',
      'category': 'Tools',
      'amount_cents': 1000,
      'currency': 'RUB',
      'billing_period': 'monthly',
      'next_payment_date': now,
      'status': 'active',
      'icon_color': 0xFF000000,
      'created_at': now,
      'updated_at': now,
    });
    await legacyDb.close();

    final upgradedDb = await database.database;
    final subscription = (await upgradedDb.query('subscriptions')).single;
    final tables = await upgradedDb.query(
      'sqlite_master',
      columns: ['name'],
      where: "type = 'table' AND name IN (?, ?)",
      whereArgs: ['subscription_usage_events', 'subscription_price_history'],
    );

    expect(subscription['title'], 'Legacy v5');
    expect(subscription['cancel_after_trial'], 0);
    expect(subscription['trial_start_at'], isNull);
    expect(subscription['last_used_at'], isNull);
    expect(tables.map((row) => row['name']).toSet(), {
      'subscription_usage_events',
      'subscription_price_history',
    });
  });

  test('database migrates version 2 data into constrained schema', () async {
    await database.close();
    final databasePath = p.join(
      await getDatabasesPath(),
      AppDatabase.databaseName,
    );
    await databaseFactory.deleteDatabase(databasePath);

    final legacyDb = await databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
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
              archive_at TEXT,
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
        },
      ),
    );
    final now = DateTime.now().toIso8601String();
    await legacyDb.insert('wallets', {
      'id': 1,
      'balance_cents': 0,
      'auto_top_up_enabled': 2,
      'auto_top_up_threshold_cents': -100,
      'auto_top_up_amount_cents': -100,
      'created_at': now,
      'updated_at': now,
    });
    await legacyDb.insert('settings', {
      'id': 1,
      'notifications_enabled': 2,
      'notify_7_days': 2,
      'notify_3_days': 2,
      'notify_1_day': 2,
      'face_id_enabled': 2,
      'timezone': 'Europe/Moscow',
      'onboarding_completed': 2,
      'created_at': now,
      'updated_at': now,
    });
    await legacyDb.insert('subscriptions', {
      'title': 'Legacy',
      'category': 'Old',
      'amount_cents': 1000,
      'currency': 'RUB',
      'billing_period': 'daily',
      'next_payment_date': now,
      'status': 'paused',
      'icon_color': 0xFF000000,
      'created_at': now,
      'updated_at': now,
    });
    await legacyDb.insert('transactions', {
      'type': 'refund',
      'amount_cents': -1000,
      'currency': 'RUB',
      'occurred_at': now,
    });
    await legacyDb.close();

    final upgradedDb = await database.database;
    final subscription = (await upgradedDb.query('subscriptions')).single;
    final transaction = (await upgradedDb.query('transactions')).single;
    final wallet = (await upgradedDb.query('wallets')).single;

    expect(subscription['billing_period'], 'monthly');
    expect(subscription['status'], 'active');
    expect(transaction['type'], 'charge');
    expect(transaction['amount_cents'], 0);
    expect(wallet['auto_top_up_enabled'], 0);
    expect(wallet['auto_top_up_threshold_cents'], 0);
  });
}

Map<String, String> _notificationSettings({
  bool days7 = true,
  bool days3 = true,
  bool days1 = true,
}) {
  return {
    'notify_7days': days7.toString(),
    'notify_3days': days3.toString(),
    'notify_1day': days1.toString(),
    'timezone': 'Europe/Moscow',
  };
}

SubscriptionData _subscriptionData({
  required int id,
  required String name,
  required double amount,
  required DateTime nextPaymentDate,
  String category = 'Tools',
  bool isActive = true,
  DateTime? archiveAt,
  DateTime? trialStartAt,
  DateTime? trialEndAt,
  bool cancelAfterTrial = false,
  DateTime? lastUsedAt,
  DateTime? inactiveSuggestionHiddenAt,
}) {
  return SubscriptionData(
    id: id,
    name: name,
    category: category,
    amount: amount,
    period: 'monthly',
    nextPaymentDate: nextPaymentDate,
    isActive: isActive,
    archiveAt: archiveAt,
    trialStartAt: trialStartAt,
    trialEndAt: trialEndAt,
    cancelAfterTrial: cancelAfterTrial,
    lastUsedAt: lastUsedAt,
    inactiveSuggestionHiddenAt: inactiveSuggestionHiddenAt,
  );
}
