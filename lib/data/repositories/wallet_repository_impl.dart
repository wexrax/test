import '../../domain/repositories/wallet_repository.dart';
import '../local/wallet_dao.dart';
import '../models/wallet_model.dart';

/// Реализация [WalletRepository] на SQLite.
class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._dao);

  final WalletDao _dao;

  @override
  Future<WalletModel> getWallet() => _dao.getWallet();

  @override
  Future<void> topUp(int amountCents, {String note = 'Пополнение'}) {
    return _dao.topUp(amountCents, note: note);
  }

  @override
  Future<void> configureAutoTopUp({
    required bool enabled,
    required int thresholdCents,
    required int amountCents,
  }) {
    return _dao.configureAutoTopUp(
      enabled: enabled,
      thresholdCents: thresholdCents,
      amountCents: amountCents,
    );
  }

  @override
  Future<bool> applyAutoTopUpIfNeeded() => _dao.applyAutoTopUpIfNeeded();
}
