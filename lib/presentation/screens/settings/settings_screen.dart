// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);

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
        ],
      ),
    );
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
}