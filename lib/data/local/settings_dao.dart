import '../models/settings_model.dart';
import 'app_database.dart';

/// Выполняет SQLite-запросы и изменения для настроек приложения.
class SettingsDao {
  const SettingsDao(this._database);

  final AppDatabase _database;

  /// Загружает единственную строку настроек.
  Future<SettingsModel> getSettings() async {
    final db = await _database.database;
    final rows = await db.query('settings', where: 'id = 1', limit: 1);
    return SettingsModel.fromMap(rows.first);
  }

  /// Обновляет телефон и состояние онбординга/входа.
  Future<void> updateAuthState({
    required String? phone,
    required bool onboardingCompleted,
  }) async {
    final db = await _database.database;
    await db.update(
        'settings',
        {
          'phone': phone,
          'onboarding_completed': onboardingCompleted ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = 1');
  }

  /// Обновляет переключатели уведомлений.
  Future<void> updateNotificationSettings({
    required bool enabled,
    required bool notify7Days,
    required bool notify3Days,
    required bool notify1Day,
  }) async {
    final db = await _database.database;
    await db.update(
        'settings',
        {
          'notifications_enabled': enabled ? 1 : 0,
          'notify_7_days': notify7Days ? 1 : 0,
          'notify_3_days': notify3Days ? 1 : 0,
          'notify_1_day': notify1Day ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = 1');
  }

  /// Обновляет локальные настройки безопасности и часовой пояс.
  Future<void> updateSecurityAndTimezone({
    required bool faceIdEnabled,
    required String timezone,
  }) async {
    final db = await _database.database;
    await db.update(
        'settings',
        {
          'face_id_enabled': faceIdEnabled ? 1 : 0,
          'timezone': timezone,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = 1');
  }

  Future<void> updateMonthlyBudget({required int? monthlyBudgetCents}) async {
    final db = await _database.database;
    await db.update(
        'settings',
        {
          'monthly_budget_cents': monthlyBudgetCents,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = 1');
  }

  Future<void> updateHiddenSavingsRecommendations(String value) async {
    final db = await _database.database;
    await db.update(
        'settings',
        {
          'hidden_savings_recommendations': value,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = 1');
  }
}
