/// Локальная SQLite-модель настроек приложения и состояния авторизации.
class SettingsModel {
  const SettingsModel({
    this.id = 1,
    this.phone,
    required this.notificationsEnabled,
    required this.notify7Days,
    required this.notify3Days,
    required this.notify1Day,
    required this.faceIdEnabled,
    required this.timezone,
    this.monthlyBudgetCents,
    this.hiddenSavingsRecommendations = '',
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String? phone;
  final bool notificationsEnabled;
  final bool notify7Days;
  final bool notify3Days;
  final bool notify1Day;
  final bool faceIdEnabled;
  final String timezone;
  final int? monthlyBudgetCents;
  final String hiddenSavingsRecommendations;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразует модель в строку SQLite.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'phone': phone,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'notify_7_days': notify7Days ? 1 : 0,
      'notify_3_days': notify3Days ? 1 : 0,
      'notify_1_day': notify1Day ? 1 : 0,
      'face_id_enabled': faceIdEnabled ? 1 : 0,
      'timezone': timezone,
      'monthly_budget_cents': monthlyBudgetCents,
      'hidden_savings_recommendations': hiddenSavingsRecommendations,
      'onboarding_completed': onboardingCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Создаёт модель настроек из строки SQLite.
  factory SettingsModel.fromMap(Map<String, Object?> map) {
    return SettingsModel(
      id: map['id'] as int,
      phone: map['phone'] as String?,
      notificationsEnabled: map['notifications_enabled'] == 1,
      notify7Days: map['notify_7_days'] == 1,
      notify3Days: map['notify_3_days'] == 1,
      notify1Day: map['notify_1_day'] == 1,
      faceIdEnabled: map['face_id_enabled'] == 1,
      timezone: map['timezone'] as String,
      monthlyBudgetCents: _nullableInt(map['monthly_budget_cents']),
      hiddenSavingsRecommendations:
          map['hidden_savings_recommendations'] as String? ?? '',
      onboardingCompleted: map['onboarding_completed'] == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static int? _nullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
