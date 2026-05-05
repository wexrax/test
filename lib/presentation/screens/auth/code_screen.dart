// lib/presentation/screens/auth/code_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

class CodeScreen extends ConsumerStatefulWidget {
  final String phone;
  const CodeScreen({super.key, required this.phone});

  @override
  ConsumerState<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends ConsumerState<CodeScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_formKey.currentState!.validate()) {
      final code = _codeController.text;
      if (code == AppLocalizations.of(context)!.demoCode) {
        await ref.read(authProvider.notifier).login(widget.phone);
        if (mounted) context.go('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неверный код')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.codeTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Введите код, отправленный на ${widget.phone}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(hintText: 'Код'),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Введите 6 цифр' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _verifyCode,
                child: Text(l10n.loginButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}