import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../domain/repositories/settings_repository.dart';
import 'merchant_provider.dart';
import 'repository_providers.dart';
import 'settings_provider.dart';
import 'subscription_provider.dart';
import 'wallet_provider.dart';

enum AuthStatus { unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final String? phone;
  final bool isLoading;

  AuthState({
    required this.status,
    this.phone,
    this.isLoading = false,
  });
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AppDatabase _database;
  final SettingsRepository _settingsRepository;
  final SubscriptionNotifier _subNotifier;
  final WalletNotifier _walletNotifier;
  final MerchantNotifier _merchantNotifier;
  final SettingsNotifier _settingsNotifier;

  AuthNotifier(
    this._database,
    this._settingsRepository,
    this._subNotifier,
    this._walletNotifier,
    this._merchantNotifier,
    this._settingsNotifier,
  ) : super(AuthState(status: AuthStatus.unauthenticated, isLoading: true)) {
    load();
  }

  Future<void> load() async {
    final settings = await _settingsRepository.getSettings();
    if (!mounted) return;
    state = AuthState(
      status: settings.phone == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated,
      phone: settings.phone,
    );
  }

  Future<void> login(String phone) async {
    await _database.seedDemoData(phone: phone);
    await _subNotifier.load();
    await _walletNotifier.load();
    await _merchantNotifier.load();
    await _settingsNotifier.load();
    state = AuthState(status: AuthStatus.authenticated, phone: phone);
  }

  Future<void> logout() async {
    await _database.clearAllData();
    await _subNotifier.clear();
    await _walletNotifier.clear();
    await _merchantNotifier.clear();
    await _settingsNotifier.load();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(appDatabaseProvider),
    ref.watch(settingsRepositoryProvider),
    ref.read(subscriptionNotifierProvider.notifier),
    ref.read(walletNotifierProvider.notifier),
    ref.read(merchantNotifierProvider.notifier),
    ref.read(settingsProvider.notifier),
  );
});
