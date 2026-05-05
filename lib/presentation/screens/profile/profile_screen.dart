// lib/presentation/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/export_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        children: [
          if (auth.phone != null)
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(l10n.phone),
              subtitle: Text(auth.phone!),
            ),
          ListTile(
            leading: const Icon(Icons.subscriptions),
            title: Text(l10n.merchantTitle),
            onTap: () => context.push('/merchants'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: Text(l10n.walletTitle),
            onTap: () => context.push('/wallet'),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(l10n.history),
            onTap: () => context.push('/history'),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(l10n.exportCsv),
            onTap: () async {
              final csv = ref.read(subscriptionsCsvProvider);
              await shareCsvFile(csv, 'subscriptions.csv');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.dataExported)),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(l10n.settings),
            onTap: () => context.push('/settings'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n.logoutButton,
                style: const TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/auth/phone');
            },
          ),
        ],
      ),
    );
  }
}