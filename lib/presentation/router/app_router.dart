// lib/presentation/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/phone_screen.dart';
import '../screens/auth/code_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/subscriptions/subscriptions_list_screen.dart';
import '../screens/subscriptions/subscription_detail_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/history/price_history_screen.dart';
import '../screens/merchant/merchant_list_screen.dart';
import '../screens/merchant/create_merchant_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/add_subscription/add_subscription_screen.dart'; // <-- импорт

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
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
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
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
            GoRoute(
                path: '/dashboard',
                builder: (_, __) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/subscriptions',
              builder: (_, state) => SubscriptionsListScreen(
                initialCategory: state.uri.queryParameters['category'],
              ),
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
            GoRoute(
                path: '/analytics',
                builder: (_, __) => const AnalyticsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),

      // Экраны вне нижней навигации
      GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(
        path: '/price-history',
        builder: (_, __) => const PriceHistoryScreen(),
      ),
      GoRoute(
          path: '/merchants', builder: (_, __) => const MerchantListScreen()),
      GoRoute(
          path: '/merchants/create',
          builder: (_, __) => const CreateMerchantScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/add-subscription',
          builder: (_, __) => const AddSubscriptionScreen()), // <-- маршрут
    ],
  );
});

/// Оболочка с нижней навигацией
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _MainBottomNavigation(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _MainBottomNavigation extends StatelessWidget {
  const _MainBottomNavigation({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _MainNavDestination(icon: Icons.dashboard, label: 'Главное'),
    _MainNavDestination(icon: Icons.subscriptions, label: 'Подписки'),
    _MainNavDestination(icon: Icons.insights, label: 'Аналитика'),
    _MainNavDestination(icon: Icons.account_balance_wallet, label: 'Кошелёк'),
    _MainNavDestination(icon: Icons.person, label: 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                for (var index = 0; index < _items.length; index++)
                  Expanded(
                    child: _MainNavItem(
                      destination: _items[index],
                      selected: currentIndex == index,
                      onTap: () => onTap(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainNavItem extends StatelessWidget {
  const _MainNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _MainNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message: destination.label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(destination.icon, color: color, size: 25),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  destination.label,
                  maxLines: 1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainNavDestination {
  const _MainNavDestination({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}
