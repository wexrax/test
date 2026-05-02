import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = const [
    {'title': 'Управляйте подписками', 'description': 'Все ваши подписки в одном месте'},
    {'title': 'Не пропускайте списания', 'description': 'Уведомления за 7, 3 и 1 день'},
    {'title': 'Кошелёк и расходы', 'description': 'Пополняйте баланс и следите за тратами'},
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    } else {
      context.go('/auth/phone');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (_, index) => Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.subscriptions, size: 100, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 40),
                      Text(_slides[index]['title']!, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Text(_slides[index]['description']!, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => context.go('/auth/phone'),
                    child: Text(l10n.onboardingSkip),
                  ),
                  Row(
                    children: List.generate(_slides.length, (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    )),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(_currentPage == _slides.length - 1 ? l10n.onboardingStart : l10n.onboardingNext),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}