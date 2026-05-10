// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final permission = ref.watch(notificationPermissionProvider);
    final scheduleSummary = ref.watch(notificationScheduleSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(l10n.notify7days),
            value: settings['notify_7days'] == 'true',
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .set('notify_7days', v.toString()),
          ),
          SwitchListTile(
            title: Text(l10n.notify3days),
            value: settings['notify_3days'] == 'true',
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .set('notify_3days', v.toString()),
          ),
          SwitchListTile(
            title: Text(l10n.notify1day),
            value: settings['notify_1day'] == 'true',
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .set('notify_1day', v.toString()),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.notificationPermissionStatus),
            subtitle: Text(_permissionLabel(l10n, permission.valueOrNull)),
          ),
          if (_canRequestPermission(permission.valueOrNull))
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(l10n.requestNotificationsPermission),
              onTap: () async {
                final state = await ref
                    .read(notificationActionsProvider)
                    .requestPermissions();
                if (state == NotificationPermissionState.granted) {
                  await ref.read(notificationActionsProvider).resyncSchedule();
                }
                ref.invalidate(notificationPermissionProvider);
              },
            ),
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: Text(l10n.refreshNotificationSchedule),
            subtitle: Text(
              l10n.notificationScheduleSummary(
                scheduleSummary.scheduledCount,
                _daysLabel(scheduleSummary.enabledDays),
              ),
            ),
            onTap: () async {
              await ref.read(notificationActionsProvider).resyncSchedule();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.notificationScheduleRefreshed)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notification_important_outlined),
            title: Text(l10n.testNotification),
            onTap: () async {
              final state = await ref
                  .read(notificationActionsProvider)
                  .showTestNotification();
              ref.invalidate(notificationPermissionProvider);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state == NotificationPermissionState.granted
                        ? l10n.testNotificationSent
                        : _permissionLabel(l10n, state),
                  ),
                ),
              );
            },
          ),
          SwitchListTile(
            title: Text(l10n.faceID),
            value: settings['face_id'] == 'true',
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .set('face_id', v.toString()),
          ),
          ListTile(
            title: Text(l10n.timezone),
            subtitle: Text(settings['timezone'] ?? 'Europe/Moscow'),
            onTap: () => _showTimezonePicker(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.savings_outlined),
            title: const Text('Личный лимит бюджета'),
            subtitle: Text(
              (settings['monthly_budget'] ?? '').isEmpty
                  ? 'Не задан'
                  : '${settings['monthly_budget']} ₽ в месяц',
            ),
            onTap: () => _showBudgetEditor(context, ref),
          ),
        ],
      ),
    );
  }

  String _permissionLabel(
    AppLocalizations l10n,
    NotificationPermissionState? state,
  ) {
    return switch (state) {
      NotificationPermissionState.granted => l10n.notificationPermissionGranted,
      NotificationPermissionState.denied => l10n.notificationPermissionDenied,
      NotificationPermissionState.unsupported =>
        l10n.notificationPermissionUnsupported,
      NotificationPermissionState.unknown ||
      null =>
        l10n.notificationPermissionUnknown,
    };
  }

  bool _canRequestPermission(NotificationPermissionState? state) {
    return state != NotificationPermissionState.granted &&
        state != NotificationPermissionState.unsupported;
  }

  String _daysLabel(Set<int> enabledDays) {
    if (enabledDays.isEmpty) return '-';
    final days = enabledDays.toList()..sort((a, b) => b.compareTo(a));
    return days.join('/');
  }

  void _showTimezonePicker(BuildContext context, WidgetRef ref) {
    const timezones = [
      'Europe/Moscow',
      'Europe/Kaliningrad',
      'Asia/Yekaterinburg',
      'Asia/Novosibirsk',
      'Asia/Krasnoyarsk',
      'Asia/Irkutsk',
      'Asia/Yakutsk',
      'Asia/Vladivostok',
      'UTC',
    ];

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final timezone in timezones)
              ListTile(
                title: Text(timezone),
                onTap: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setTimezone(timezone);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBudgetEditor(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(settingsProvider)['monthly_budget'] ?? '';
    final controller = TextEditingController(text: current);
    final result = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Личный лимит бюджета'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Лимит в месяц',
            suffixText: '₽',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 0),
            child: const Text('Сбросить'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );
              Navigator.pop(ctx, value);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    await ref.read(settingsProvider.notifier).setMonthlyBudget(result);
  }
}
