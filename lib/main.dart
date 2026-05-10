// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'data/local/app_database.dart';
import 'data/local/subscription_dao.dart';
import 'core/services/archive_timer_service.dart';
import 'core/themes/light_theme.dart';
import 'core/themes/dark_theme.dart';
import 'core/services/notification_service.dart';
import 'presentation/providers/subscription_provider.dart';
import 'presentation/providers/wallet_provider.dart';
import 'presentation/router/app_router.dart';
import 'presentation/providers/reminder_provider.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize(
    onPayload: _handleNotificationPayload,
  );
  await ArchiveTimerService.instance.initialize();
  await ArchiveTimerService.instance.reconcileDue();
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _handleNotificationPayload(String payload) async {
  final route = await _notificationRouteForPayload(payload);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    context.go(route);
  });
}

Future<String> _notificationRouteForPayload(String payload) async {
  if (payload == 'test:notification') return '/settings';

  final separatorIndex = payload.indexOf(':');
  if (separatorIndex == -1) return '/subscriptions';

  final type = payload.substring(0, separatorIndex);
  if (type != 'subscription' && type != 'archive') return '/subscriptions';

  final id = int.tryParse(payload.substring(separatorIndex + 1));
  if (id == null) return '/subscriptions';

  final subscription = await SubscriptionDao(AppDatabase.instance).getById(id);
  if (subscription == null) return '/subscriptions';
  return '/subscriptions/$id';
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(walletNotifierProvider.notifier).applyStartupAutoTopUp();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(subscriptionNotifierProvider.notifier).archiveDueSubscriptions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    ref.watch(subscriptionReminderSyncProvider);
    return MaterialApp.router(
      title: 'Мои Подписки',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system, // автоматически переключает тему
      routerConfig: router,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
