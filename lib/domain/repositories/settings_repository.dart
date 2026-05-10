import '../../data/models/settings_model.dart';

/// Контракт для чтения и обновления настроек приложения.
abstract class SettingsRepository {
  /// Возвращает единственную локальную строку настроек.
  Future<SettingsModel> getSettings();

  /// Обновляет телефон и состояние онбординга/входа.
  Future<void> updateAuthState({
    required String? phone,
    required bool onboardingCompleted,
  });

  /// Обновляет настройки напоминаний.
  Future<void> updateNotificationSettings({
    required bool enabled,
    required bool notify7Days,
    required bool notify3Days,
    required bool notify1Day,
  });

  /// Обновляет локальные настройки биометрии и часовой пояс.
  Future<void> updateSecurityAndTimezone({
    required bool faceIdEnabled,
    required String timezone,
  });

  /// Обновляет личный месячный лимит бюджета.
  Future<void> updateMonthlyBudget({required int? monthlyBudgetCents});

  /// Обновляет список скрытых рекомендаций по экономии.
  Future<void> updateHiddenSavingsRecommendations(String value);
}
