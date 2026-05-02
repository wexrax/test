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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  return GoRouter(
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
      GoRoute(path: '/auth/code', builder: (_, state) => CodeScreen(phone: state.uri.queryParameters['phone'] ?? '')),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/subscriptions', builder: (_, __) => const SubscriptionsListScreen()),
      GoRoute(path: '/subscriptions/:id', builder: (_, state) => SubscriptionDetailScreen(id: int.parse(state.pathParameters['id']!))),
      GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
      GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/merchants', builder: (_, __) => const MerchantListScreen()),
      GoRoute(path: '/merchants/create', builder: (_, __) => const CreateMerchantScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
});