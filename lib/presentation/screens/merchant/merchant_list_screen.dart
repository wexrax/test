import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/merchant_provider.dart';

class MerchantListScreen extends ConsumerWidget {
  const MerchantListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final merchants = ref.watch(merchantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.merchantTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/merchants/create'),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: merchants.length,
        itemBuilder: (_, i) {
          final m = merchants[i];
          return Card(
            child: ListTile(
              title: Text(m.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.description),
                  Text(l10n.subscribersCount(m.subscriberCount.toString())),
                  Text(l10n.earned(m.earned.rub)),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    m.price.rub,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(m.period == 'monthly' ? 'мес' : 'год'),
                ],
              ),
              onTap: () => _showActions(context, ref, m),
            ),
          );
        },
      ),
    );
  }

  void _showActions(
      BuildContext context, WidgetRef ref, MerchantData merchant) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Ссылка'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ссылка скопирована (заглушка)'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text('Вывод'),
              onTap: () async {
                Navigator.pop(context);
                if (merchant.earned >= 100) {
                  await ref
                      .read(merchantNotifierProvider.notifier)
                      .withdraw(merchant.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Вывод выполнен')),
                    );
                  }
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Минимальная сумма 100 ₽')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
