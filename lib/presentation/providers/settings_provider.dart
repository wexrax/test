// lib/presentation/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/settings_repository.dart';
import 'repository_providers.dart';

class SettingsNotifier extends StateNotifier<Map<String, String>> {
  SettingsNotifier(this._repository)
      : super({
          'notify_7days': 'false',
          'notify_3days': 'false',
          'notify_1day': 'false',
          'face_id': 'false',
          'timezone': 'Europe/Moscow',
          'monthly_budget': '',
          'hidden_savings_recommendations': '',
        }) {
    load();
  }

  final SettingsRepository _repository;

  Future<void> load() async {
    final settings = await _repository.getSettings();
    if (!mounted) return;
    state = {
      'notify_7days': settings.notify7Days.toString(),
      'notify_3days': settings.notify3Days.toString(),
      'notify_1day': settings.notify1Day.toString(),
      'face_id': settings.faceIdEnabled.toString(),
      'timezone': settings.timezone,
      'monthly_budget': settings.monthlyBudgetCents == null
          ? ''
          : (settings.monthlyBudgetCents! / 100).toStringAsFixed(0),
      'hidden_savings_recommendations': settings.hiddenSavingsRecommendations,
    };
  }

  Future<void> set(String key, String value) async {
    final next = {...state, key: value};
    state = next;
    await _repository.updateNotificationSettings(
      enabled: next['notify_7days'] == 'true' ||
          next['notify_3days'] == 'true' ||
          next['notify_1day'] == 'true',
      notify7Days: next['notify_7days'] == 'true',
      notify3Days: next['notify_3days'] == 'true',
      notify1Day: next['notify_1day'] == 'true',
    );
    await _repository.updateSecurityAndTimezone(
      faceIdEnabled: next['face_id'] == 'true',
      timezone: next['timezone'] ?? 'Europe/Moscow',
    );
  }

  Future<void> setTimezone(String timezone) async {
    await set('timezone', timezone);
  }

  Future<void> setMonthlyBudget(double? amount) async {
    final normalized = amount == null || amount <= 0 ? null : amount;
    state = {
      ...state,
      'monthly_budget': normalized == null ? '' : normalized.toStringAsFixed(0),
    };
    await _repository.updateMonthlyBudget(
      monthlyBudgetCents:
          normalized == null ? null : (normalized * 100).round(),
    );
  }

  Future<void> hideSavingsRecommendation(String key) async {
    final hidden = hiddenSavingsRecommendationKeys(state)..add(key);
    final serialized = hidden.join('|');
    state = {...state, 'hidden_savings_recommendations': serialized};
    await _repository.updateHiddenSavingsRecommendations(serialized);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Map<String, String>>(
  (ref) => SettingsNotifier(ref.watch(settingsRepositoryProvider)),
);

Set<String> hiddenSavingsRecommendationKeys(Map<String, String> settings) {
  final serialized = settings['hidden_savings_recommendations'] ?? '';
  if (serialized.isEmpty) return <String>{};
  return serialized.split('|').where((key) => key.trim().isNotEmpty).toSet();
}
