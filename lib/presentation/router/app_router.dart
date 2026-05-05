// lib/presentation/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/phone_screen.dart';
import '../screens/auth/code_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/subscriptions/subscriptions_list_screen.dart';
import '../screens/subscriptions/subscription_detail_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/merchant/merchant_list_screen.dart';
import '../screens/merchant/create_merchant_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/add_subscription/add_subscription_screen.dart'; // <-- импорт

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isAuth = state.matchedLocation.startsWith('/auth');
      if (!isLoggedIn && !isOnboarding && !isAuth) return '/onboarding';
      if (isLoggedIn && (isOnboarding || isAuth)) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth/phone', builder: (_, __) => const PhoneScreen()),
      GoRoute(
        path: '/auth/code',
        builder: (_, state) => CodeScreen(
          phone: state.uri.queryParameters['phone'] ?? '',
        ),
      ),

      // ShellRoute с нижней навигацией
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/subscriptions',
              builder: (_, __) => const SubscriptionsListScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => SubscriptionDetailScreen(
                    id: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),

      // Экраны вне нижней навигации
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/merchants', builder: (_, __) => const MerchantListScreen()),
      GoRoute(path: '/merchants/create', builder: (_, __) => const CreateMerchantScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/add-subscription', builder: (_, __) => const AddSubscriptionScreen()), // <-- маршрут
    ],
  );
});

/// Оболочка с BottomNavigationBar
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Дашборд'),
          BottomNavigationBarItem(icon: Icon(Icons.subscriptions), label: 'Подписки'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Календарь'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Кошелёк'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}