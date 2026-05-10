// lib/presentation/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/export_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/wallet_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final activeSubscriptions = ref.watch(activeSubscriptionsProvider);
    final monthlyCost = ref.watch(monthlyCostProvider);
    final wallet = ref.watch(walletNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            _ProfileHeroCard(
              eyebrow: l10n.profilePremiumEyebrow,
              title: l10n.profileTitle,
              displayName: l10n.profileDefaultName,
              phone: auth.phone ?? '',
              settingsLabel: l10n.settings,
              onSettingsTap: () => context.push('/settings'),
            ),
            const SizedBox(height: 14),
            _ProfileStatsStrip(
              stats: [
                _ProfileStatData(
                  label: l10n.profileActiveStat,
                  value: activeSubscriptions.length.toString(),
                  icon: Icons.subscriptions,
                  color: AppColors.walletBlue,
                ),
                _ProfileStatData(
                  label: l10n.profileMonthlyPlanStat,
                  value: monthlyCost.rub,
                  icon: Icons.auto_graph,
                  color: const Color(0xFFD84E93),
                ),
                _ProfileStatData(
                  label: l10n.profileWalletStat,
                  value: wallet.balance.rub,
                  icon: Icons.account_balance_wallet,
                  color: const Color(0xFF008A62),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.profileActionsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            _ProfileActionGrid(
              actions: [
                _ProfileActionData(
                  title: l10n.merchantTitle,
                  subtitle: l10n.profileMerchantSubtitle,
                  icon: Icons.storefront,
                  color: const Color(0xFF7B55E7),
                  onTap: () => context.push('/merchants'),
                ),
                _ProfileActionData(
                  title: l10n.walletTitle,
                  subtitle: l10n.profileWalletSubtitle,
                  icon: Icons.account_balance_wallet,
                  color: AppColors.walletBlue,
                  onTap: () => context.push('/wallet'),
                ),
                _ProfileActionData(
                  title: l10n.history,
                  subtitle: l10n.profileHistorySubtitle,
                  icon: Icons.receipt_long,
                  color: const Color(0xFF008A62),
                  onTap: () => context.push('/history'),
                ),
                _ProfileActionData(
                  title: l10n.profileExportTitle,
                  subtitle: l10n.profileExportSubtitle,
                  icon: Icons.file_download_outlined,
                  color: const Color(0xFFD84E93),
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
              ],
            ),
            const SizedBox(height: 18),
            _LogoutButton(
              label: l10n.logoutButton,
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/auth/phone');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.eyebrow,
    required this.title,
    required this.displayName,
    required this.phone,
    required this.settingsLabel,
    required this.onSettingsTap,
  });

  final String eyebrow;
  final String title;
  final String displayName;
  final String phone;
  final String settingsLabel;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarLetter =
        displayName.trim().isEmpty ? '?' : displayName.trim()[0].toUpperCase();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusExtraLarge),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(AppDimens.radiusExtraLarge),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 22,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -42,
              top: 18,
              child: Transform.rotate(
                angle: -0.42,
                child: const _ProfileAccentBand(
                  width: 178,
                  height: 28,
                  color: AppColors.primary,
                  opacity: 0.78,
                ),
              ),
            ),
            Positioned(
              right: -18,
              bottom: 34,
              child: Transform.rotate(
                angle: -0.42,
                child: const _ProfileAccentBand(
                  width: 126,
                  height: 18,
                  color: AppColors.walletBlue,
                  opacity: 0.34,
                ),
              ),
            ),
            Positioned(
              left: -22,
              bottom: 26,
              child: Transform.rotate(
                angle: -0.42,
                child: const _ProfileAccentBand(
                  width: 140,
                  height: 18,
                  color: Colors.white,
                  opacity: 0.12,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eyebrow,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.66),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              title,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: settingsLabel,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onSettingsTap,
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 3,
                          ),
                        ),
                        child: Text(
                          avatarLetter,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Text(
                                phone.isEmpty ? '—' : phone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _ProfileAccentBand extends StatelessWidget {
  const _ProfileAccentBand({
    required this.width,
    required this.height,
    required this.color,
    required this.opacity,
  });

  final double width;
  final double height;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _ProfileStatsStrip extends StatelessWidget {
  const _ProfileStatsStrip({required this.stats});

  final List<_ProfileStatData> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          for (var index = 0; index < stats.length; index++) ...[
            Expanded(child: _ProfileStatItem(data: stats[index])),
            if (index != stats.length - 1)
              Container(
                width: 1,
                height: 56,
                color: AppColors.divider,
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  const _ProfileStatItem({required this.data});

  final _ProfileStatData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(data.icon, color: data.color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionGrid extends StatelessWidget {
  const _ProfileActionGrid({required this.actions});

  final List<_ProfileActionData> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final action in actions)
              SizedBox(
                width: itemWidth,
                child: _ProfileActionTile(action: action),
              ),
          ],
        );
      },
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({required this.action});

  final _ProfileActionData action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        child: Container(
          constraints: const BoxConstraints(minHeight: 136),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(action.icon, color: action.color, size: 21),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward,
                    color: action.color,
                    size: 19,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                action.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStatData {
  const _ProfileStatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _ProfileActionData {
  const _ProfileActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.logout, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
