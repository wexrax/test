import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/wallet_provider.dart';

class TopUpModal extends ConsumerStatefulWidget {
  const TopUpModal({super.key});

  @override
  ConsumerState<TopUpModal> createState() => _TopUpModalState();
}

class _TopUpModalState extends ConsumerState<TopUpModal> {
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.topUpModalTitle),
      content: TextField(
        controller: _amountCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(hintText: l10n.enterAmount),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: () async {
            final amount = double.tryParse(_amountCtrl.text) ?? 0;
            if (amount > 0) {
              await ref.read(walletNotifierProvider.notifier).topUp(amount);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}
