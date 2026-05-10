// lib/presentation/screens/merchant/create_merchant_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/merchant_provider.dart';

class CreateMerchantScreen extends ConsumerStatefulWidget {
  const CreateMerchantScreen({super.key});

  @override
  ConsumerState<CreateMerchantScreen> createState() =>
      _CreateMerchantScreenState();
}

class _CreateMerchantScreenState extends ConsumerState<CreateMerchantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _period = 'monthly';

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final merchant = MerchantData(
        id: 0,
        name: _nameCtrl.text,
        description: _descCtrl.text,
        price: double.parse(_priceCtrl.text),
        period: _period,
        subscriberCount: 0,
        earned: 0,
      );
      await ref.read(merchantNotifierProvider.notifier).add(merchant);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createMerchant)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: l10n.name),
                validator: (v) => v!.isEmpty ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(labelText: l10n.description),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.price),
                validator: (v) => v!.isEmpty || double.tryParse(v) == null
                    ? 'Введите цену'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _period,
                decoration: InputDecoration(labelText: l10n.period),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('В месяц')),
                  DropdownMenuItem(value: 'yearly', child: Text('В год')),
                ],
                onChanged: (v) => setState(() => _period = v!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: Text(l10n.createMerchant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
