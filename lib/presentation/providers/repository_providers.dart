// lib/presentation/providers/repository_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/app_database.dart';
import '../../data/local/merchant_subscription_dao.dart';
import '../../data/local/settings_dao.dart';
import '../../data/local/subscription_dao.dart';
import '../../data/local/transaction_dao.dart';
import '../../data/local/wallet_dao.dart';
import '../../data/repositories/merchant_subscription_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/repositories/merchant_subscription_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/wallet_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepositoryImpl(
    SubscriptionDao(ref.watch(appDatabaseProvider)),
  );
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(
    WalletDao(ref.watch(appDatabaseProvider)),
  );
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(
    TransactionDao(ref.watch(appDatabaseProvider)),
  );
});

final merchantSubscriptionRepositoryProvider = Provider<MerchantSubscriptionRepository>((ref) {
  return MerchantSubscriptionRepositoryImpl(
    MerchantSubscriptionDao(ref.watch(appDatabaseProvider)),
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    SettingsDao(ref.watch(appDatabaseProvider)),
  );
});