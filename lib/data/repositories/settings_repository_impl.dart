import '../../domain/repositories/settings_repository.dart';
import '../local/settings_dao.dart';
import '../models/settings_model.dart';

/// Реализация [SettingsRepository] на SQLite.
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._dao);

  final SettingsDao _dao;

  @override
  Future<SettingsModel> getSettings() => _dao.getSettings();

  @override
  Future<void> updateAuthState({
    required String? phone,
    required bool onboardingCompleted,
  }) {
    return _dao.updateAuthState(
      phone: phone,
      onboardingCompleted: onboardingCompleted,
    );
  }

  @override
  Future<void> updateNotificationSettings({
    required bool enabled,
    required bool notify7Days,
    required bool notify3Days,
    required bool notify1Day,
  }) {
    return _dao.updateNotificationSettings(
      enabled: enabled,
      notify7Days: notify7Days,
      notify3Days: notify3Days,
      notify1Day: notify1Day,
    );
  }

  @override
  Future<void> updateSecurityAndTimezone({
    required bool faceIdEnabled,
    required String timezone,
  }) {
    return _dao.updateSecurityAndTimezone(
      faceIdEnabled: faceIdEnabled,
      timezone: timezone,
    );
  }
}
