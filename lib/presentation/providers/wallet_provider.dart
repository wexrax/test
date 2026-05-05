// lib/presentation/providers/wallet_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'repository_providers.dart';

class TransactionData {
  final int id;
  final String type;
  final double amount;
  final DateTime date;
  final String description;
  final int? subscriptionId;

  TransactionData({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    this.subscriptionId,
  });
}

class WalletState {
  final double balance;
  final bool autoTopUpEnabled;
  final double autoTopUpThreshold;
  final double autoTopUpAmount;
  final List<TransactionData> transactions;

  WalletState({
    required this.balance,
    required this.autoTopUpEnabled,
    required this.autoTopUpThreshold,
    required this.autoTopUpAmount,
    required this.transactions,
  });

  WalletState copyWith({
    double? balance,
    bool? autoTopUpEnabled,
    double? autoTopUpThreshold,
    double? autoTopUpAmount,
    List<TransactionData>? transactions,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      autoTopUpEnabled: autoTopUpEnabled ?? this.autoTopUpEnabled,
      autoTopUpThreshold: autoTopUpThreshold ?? this.autoTopUpThreshold,
      autoTopUpAmount: autoTopUpAmount ?? this.autoTopUpAmount,
      transactions: transactions ?? this.transactions,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier(this._walletRepository, this._transactionRepository)
      : super(WalletState(
          balance: 0,
          autoTopUpEnabled: false,
          autoTopUpThreshold: 1000,
          autoTopUpAmount: 5000,
          transactions: [],
        )) {
    load();
  }

  final WalletRepository _walletRepository;
  final TransactionRepository _transactionRepository;

  Future<void> load() async {
    await _walletRepository.applyAutoTopUpIfNeeded();
    final wallet = await _walletRepository.getWallet();
    final transactions = await _transactionRepository.getRecent(limit: 50);
    if (!mounted) return;
    state = WalletState(
      balance: wallet.balanceCents / 100,
      autoTopUpEnabled: wallet.autoTopUpEnabled,
      autoTopUpThreshold: wallet.autoTopUpThresholdCents / 100,
      autoTopUpAmount: wallet.autoTopUpAmountCents / 100,
      transactions: transactions.map((transaction) {
        return TransactionData(
          id: transaction.id ?? 0,
          type: transaction.type == 'charge' ? 'payment' : 'topup',
          amount: transaction.amountCents / 100,
          date: transaction.occurredAt,
          description: transaction.note ?? '',
          subscriptionId: transaction.subscriptionId,
        );
      }).toList(),
    );
  }

  Future<void> topUp(double amount) async {
    if (amount <= 0) return;
    await _walletRepository.topUp(_rubToCents(amount));
    await load();
  }

  Future<bool> deduct(
    double amount,
    String description, {
    int? subscriptionId,
  }) async {
    return state.balance >= amount;
  }

  Future<void> clear() async {
    state = WalletState(
      balance: 0,
      autoTopUpEnabled: false,
      autoTopUpThreshold: 1000,
      autoTopUpAmount: 5000,
      transactions: [],
    );
  }

  Future<void> updateAutoTopUp({
    bool? enabled,
    double? threshold,
    double? amount,
  }) async {
    await _walletRepository.configureAutoTopUp(
      enabled: enabled ?? state.autoTopUpEnabled,
      thresholdCents: _rubToCents(threshold ?? state.autoTopUpThreshold),
      amountCents: _rubToCents(amount ?? state.autoTopUpAmount),
    );
    await load();
  }

  int _rubToCents(double amount) => (amount * 100).round();
}

final walletNotifierProvider =
    StateNotifierProvider<WalletNotifier, WalletState>(
  (ref) => WalletNotifier(
    ref.watch(walletRepositoryProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);

final filteredTransactionsProvider =
    Provider.family<List<TransactionData>, String>((ref, period) {
  final wallet = ref.watch(walletNotifierProvider);
  final now = DateTime.now();
  DateTime start;
  switch (period) {
    case 'month':
      start = DateTime(now.year, now.month, 1);
      break;
    case 'quarter':
      final quarterStart = ((now.month - 1) ~/ 3) * 3 + 1;
      start = DateTime(now.year, quarterStart, 1);
      break;
    case 'year':
      start = DateTime(now.year, 1, 1);
      break;
    default:
      start = DateTime(now.year, now.month, 1);
  }
  return wallet.transactions
      .where((t) => t.date.isAfter(start) || t.date.isAtSameMomentAs(start))
      .toList();
});