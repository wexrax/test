// lib/presentation/screens/analytics/analytics_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/export_utils.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/wallet_provider.dart';

final _analyticsPeriodProvider =
    StateProvider<_AnalyticsPeriod>((ref) => _AnalyticsPeriod.month);

enum _AnalyticsPeriod { week, month, year }

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsSnapshotProvider);
    final wallet = ref.watch(walletNotifierProvider);
    final period = ref.watch(_analyticsPeriodProvider);
    _AnalyticsPalette.resolve(context);

    return analyticsAsync.when(
      data: (analytics) => Scaffold(
        backgroundColor: _AnalyticsPalette.canvas,
        body: RefreshIndicator(
          color: _AnalyticsPalette.accent,
          backgroundColor: _AnalyticsPalette.panel,
          onRefresh: () async {
            await ref.read(subscriptionNotifierProvider.notifier).load();
            await ref.read(walletNotifierProvider.notifier).load();
            ref.invalidate(analyticsSnapshotProvider);
          },
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                _AnalyticsHeader(
                  period: period,
                  onPeriodChanged: (value) =>
                      ref.read(_analyticsPeriodProvider.notifier).state = value,
                  onExport: () async {
                    final csv = ref.read(subscriptionsCsvProvider);
                    await shareCsvFile(csv, 'subscriptions.csv');
                  },
                ),
                const SizedBox(height: 18),
                _KpiGridV2(analytics: analytics),
                const SizedBox(height: 14),
                _ResponsiveAnalyticsGrid(
                  left: _SpendingBarChartCard(analytics: analytics),
                  right: _CategoryDonutCard(analytics: analytics),
                ),
                if (analytics.upcomingPayments.isNotEmpty ||
                    analytics.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  if (analytics.upcomingPayments.isNotEmpty &&
                      analytics.recommendations.isNotEmpty)
                    _ResponsiveAnalyticsGrid(
                      left: _UpcomingPanel(
                        subscriptions: analytics.upcomingPayments,
                        onOpenAll: () => context.push('/calendar'),
                        onSubscriptionTap: (id) =>
                            context.push('/subscriptions/$id'),
                      ),
                      right: _RecommendationPanelV2(
                        analytics: analytics,
                        onHide: (key) => ref
                            .read(settingsProvider.notifier)
                            .hideSavingsRecommendation(key),
                      ),
                    )
                  else if (analytics.upcomingPayments.isNotEmpty)
                    _UpcomingPanel(
                      subscriptions: analytics.upcomingPayments,
                      onOpenAll: () => context.push('/calendar'),
                      onSubscriptionTap: (id) =>
                          context.push('/subscriptions/$id'),
                    )
                  else
                    _RecommendationPanelV2(
                      analytics: analytics,
                      onHide: (key) => ref
                          .read(settingsProvider.notifier)
                          .hideSavingsRecommendation(key),
                    ),
                ],
                if (analytics.trials.isNotEmpty ||
                    analytics.inactiveSubscriptions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  if (analytics.trials.isNotEmpty &&
                      analytics.inactiveSubscriptions.isNotEmpty)
                    _ResponsiveAnalyticsGrid(
                      left: _TrialPanel(
                        trials: analytics.trials,
                        onToggleAutoCancel: (id, value) {
                          ref
                              .read(subscriptionNotifierProvider.notifier)
                              .setCancelAfterTrial(id, value);
                        },
                        onSubscriptionTap: (id) =>
                            context.push('/subscriptions/$id'),
                      ),
                      right: _InactivePanel(
                        insights: analytics.inactiveSubscriptions,
                        onArchive: (id) {
                          ref
                              .read(subscriptionNotifierProvider.notifier)
                              .archive(id);
                        },
                        onHide: (id) {
                          ref
                              .read(subscriptionNotifierProvider.notifier)
                              .hideInactiveSuggestion(id);
                        },
                        onSubscriptionTap: (id) =>
                            context.push('/subscriptions/$id'),
                      ),
                    )
                  else if (analytics.trials.isNotEmpty)
                    _TrialPanel(
                      trials: analytics.trials,
                      onToggleAutoCancel: (id, value) {
                        ref
                            .read(subscriptionNotifierProvider.notifier)
                            .setCancelAfterTrial(id, value);
                      },
                      onSubscriptionTap: (id) =>
                          context.push('/subscriptions/$id'),
                    )
                  else
                    _InactivePanel(
                      insights: analytics.inactiveSubscriptions,
                      onArchive: (id) {
                        ref
                            .read(subscriptionNotifierProvider.notifier)
                            .archive(id);
                      },
                      onHide: (id) {
                        ref
                            .read(subscriptionNotifierProvider.notifier)
                            .hideInactiveSuggestion(id);
                      },
                      onSubscriptionTap: (id) =>
                          context.push('/subscriptions/$id'),
                    ),
                ],
                const SizedBox(height: 14),
                _ForecastPanel(analytics: analytics),
                if (analytics.monthlyBudget != null) ...[
                  const SizedBox(height: 14),
                  _BudgetPanel(analytics: analytics),
                ],
                const SizedBox(height: 14),
                _WalletPanel(
                  wallet: wallet,
                  monthlyCost: analytics.plannedMonthlyCost,
                  onTap: () => context.push('/wallet'),
                ),
                const SizedBox(height: 14),
                _QuickActionStripV2(
                  onAdd: () => context.push('/add-subscription'),
                  onCalendar: () => context.push('/calendar'),
                  onHistory: () => context.push('/history'),
                  onPriceHistory: () => context.push('/price-history'),
                  onExport: () async {
                    final csv = ref.read(subscriptionsCsvProvider);
                    await shareCsvFile(csv, 'subscriptions.csv');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      loading: () => _AnalyticsStateScaffold(
        child: CircularProgressIndicator(color: _AnalyticsPalette.accent),
      ),
      error: (error, stackTrace) => _AnalyticsStateScaffold(
        child: Text(
          'Не удалось загрузить аналитику',
          style: TextStyle(
            color: _AnalyticsPalette.text,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AnalyticsStateScaffold extends StatelessWidget {
  const _AnalyticsStateScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AnalyticsPalette.canvas,
      body: SafeArea(
        child: Center(child: child),
      ),
    );
  }
}

class _AnalyticsPalette {
  static Color canvas = const Color(0xFF08090F);
  static Color panel = const Color(0xFF14151F);
  static Color panelStrong = const Color(0xFF1A1B28);
  static Color border = const Color(0xFF272A38);
  static Color text = const Color(0xFFF5F6FF);
  static Color muted = const Color(0xFF8B90A4);
  static Color accent = AppColors.primary;
  static Color onAccent = AppColors.textPrimary;
  static Color accent2 = const Color(0xFFFF9F43);
  static Color green = const Color(0xFF28D99D);
  static Color amber = const Color(0xFFFFC83D);
  static Color red = const Color(0xFFFF5C66);
  static Color blue = const Color(0xFF65A4FF);
  static Color savingsPanel = const Color(0xFF14151F);
  static Color savingsBorder = const Color(0xFF272A38);
  static Color warningPanel = const Color(0xFF14151F);
  static Color warningBorder = const Color(0xFF272A38);
  static Color recommendationPanel = const Color(0xFF14151F);
  static Color recommendationBorder = const Color(0xFF272A38);
  static Color forecastPanel = const Color(0xFF14151F);
  static Color forecastBorder = const Color(0xFF272A38);
  static Color chartGrid = const Color(0xFF2A2D3A);
  static Color progressTrack = const Color(0xFF272A38);
  static Color shadow = const Color(0x66000000);

  static void resolve(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      canvas = const Color(0xFF1A1A1A);
      panel = const Color(0xFF2C2C2C);
      panelStrong = const Color(0xFF3A3322);
      border = const Color(0xFF3A3A3A);
      text = Colors.white;
      muted = Colors.white70;
      accent = AppColors.primary;
      onAccent = AppColors.textPrimary;
      accent2 = const Color(0xFFFF9F43);
      green = const Color(0xFF28D99D);
      amber = const Color(0xFFFFC83D);
      red = const Color(0xFFFF5C66);
      blue = const Color(0xFF65A4FF);
      savingsPanel = panel;
      savingsBorder = border;
      warningPanel = panel;
      warningBorder = border;
      recommendationPanel = panel;
      recommendationBorder = border;
      forecastPanel = panel;
      forecastBorder = border;
      chartGrid = const Color(0xFF3A3A3A);
      progressTrack = const Color(0xFF3A3A3A);
      shadow = const Color(0x66000000);
      return;
    }

    canvas = AppColors.background;
    panel = AppColors.surface;
    panelStrong = const Color(0xFFFFF6DA);
    border = const Color(0xFFEDE3C7);
    text = AppColors.textPrimary;
    muted = AppColors.textSecondary;
    accent = AppColors.primary;
    onAccent = AppColors.textPrimary;
    accent2 = const Color(0xFFFF9F43);
    green = const Color(0xFF008A62);
    amber = const Color(0xFFC99200);
    red = const Color(0xFFE33C4A);
    blue = AppColors.walletBlue;
    savingsPanel = panel;
    savingsBorder = border;
    warningPanel = panel;
    warningBorder = border;
    recommendationPanel = panel;
    recommendationBorder = border;
    forecastPanel = panel;
    forecastBorder = border;
    chartGrid = const Color(0xFFE8E8E8);
    progressTrack = const Color(0xFFEDE9DC);
    shadow = AppColors.cardShadow;
  }
}

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({
    required this.period,
    required this.onPeriodChanged,
    required this.onExport,
  });

  final _AnalyticsPeriod period;
  final ValueChanged<_AnalyticsPeriod> onPeriodChanged;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    Widget titleBlock() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Аналитика',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _AnalyticsPalette.text,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Факт списаний и план подписок',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _AnalyticsPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final periodToggle = _PeriodToggle(
          selected: period,
          onChanged: onPeriodChanged,
        );

        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock(),
              const SizedBox(height: 12),
              Row(
                children: [
                  periodToggle,
                  const Spacer(),
                  _ExportButton(onTap: onExport),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock()),
            const SizedBox(width: 10),
            periodToggle,
            const SizedBox(width: 8),
            _ExportButton(onTap: onExport),
          ],
        );
      },
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({
    required this.selected,
    required this.onChanged,
  });

  final _AnalyticsPeriod selected;
  final ValueChanged<_AnalyticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _AnalyticsPalette.panelStrong,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _AnalyticsPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PeriodSegment(
            label: 'Неделя',
            selected: selected == _AnalyticsPeriod.week,
            onTap: () => onChanged(_AnalyticsPeriod.week),
          ),
          _PeriodSegment(
            label: 'Месяц',
            selected: selected == _AnalyticsPeriod.month,
            onTap: () => onChanged(_AnalyticsPeriod.month),
          ),
          _PeriodSegment(
            label: 'Год',
            selected: selected == _AnalyticsPeriod.year,
            onTap: () => onChanged(_AnalyticsPeriod.year),
          ),
        ],
      ),
    );
  }
}

class _PeriodSegment extends StatelessWidget {
  const _PeriodSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _AnalyticsPalette.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color:
                selected ? _AnalyticsPalette.onAccent : _AnalyticsPalette.muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Экспорт',
      child: Material(
        color: _AnalyticsPalette.panelStrong,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: SizedBox(
            height: 34,
            width: 42,
            child: Icon(
              Icons.file_download_outlined,
              color: _AnalyticsPalette.text,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiGridV2 extends StatelessWidget {
  const _KpiGridV2({required this.analytics});

  final AnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _KpiCard(
              width: width,
              label: 'Всего за месяц',
              value: analytics.actualMonthSpent.rub,
              detail: analytics.hasPreviousActualMonthSpent
                  ? '${_signedPercent(analytics.actualMonthChangePercent)} к прошлому месяцу'
                  : 'нет прошлого факта',
              detailColor: analytics.hasPreviousActualMonthSpent
                  ? analytics.actualMonthChangePercent > 0
                      ? _AnalyticsPalette.red
                      : _AnalyticsPalette.green
                  : _AnalyticsPalette.muted,
              accentColor: _AnalyticsPalette.accent,
              onTap: () => _showDetails(
                context,
                'Всего за месяц',
                [
                  'Текущий месячный план активных подписок: ${analytics.actualMonthSpent.rub}',
                  analytics.hasPreviousActualMonthSpent
                      ? 'Факт списаний за прошлый месяц: ${analytics.previousActualMonthSpent.rub}'
                      : 'За прошлый месяц фактических списаний нет.',
                  'Динамика считается как текущий план vs прошлый факт.',
                ],
              ),
            ),
            _KpiCard(
              width: width,
              label: 'Средний чек',
              value: analytics.actualAverageCheck.rub,
              detail: analytics.hasPreviousAverageCheck
                  ? '${_signedPercent(analytics.actualAverageCheckChangePercent)} к прошлому месяцу'
                  : 'активные подписки',
              detailColor: analytics.hasPreviousAverageCheck
                  ? analytics.actualAverageCheckChangePercent > 0
                      ? _AnalyticsPalette.red
                      : _AnalyticsPalette.green
                  : _AnalyticsPalette.muted,
              accentColor: _AnalyticsPalette.amber,
              onTap: () => _showDetails(
                context,
                'Средний чек',
                [
                  'Текущий план / количество активных подписок: ${analytics.actualAverageCheck.rub}',
                  analytics.hasPreviousAverageCheck
                      ? 'Прошлый фактический средний чек: ${analytics.previousActualAverageCheck.rub}'
                      : 'За прошлый месяц фактических чеков нет.',
                ],
              ),
            ),
            _KpiCard(
              width: width,
              label: 'Прогноз года',
              value: analytics.yearlyForecast.rub,
              detail: 'текущий месяц × 12',
              detailColor: _AnalyticsPalette.muted,
              accentColor: _AnalyticsPalette.blue,
              onTap: () => _showDetails(
                context,
                'Прогноз года',
                [
                  'Прогноз: ${analytics.yearlyForecast.rub}',
                  'Формула: текущие траты в месяц × 12.',
                ],
              ),
            ),
            if (analytics.recommendations.isNotEmpty)
              _KpiCard(
                width: width,
                label: 'Можно сэкономить',
                value: analytics.potentialSavings.rub,
                detail: 'в год',
                detailColor: _AnalyticsPalette.green,
                accentColor: _AnalyticsPalette.green,
                highlighted: true,
                onTap: () => _showDetails(
                  context,
                  'Можно сэкономить',
                  analytics.recommendations
                      .map(
                        (item) =>
                            '${item.subscription.name} -> ${item.alternativeName}: ${item.annualSavings.rub} в год',
                      )
                      .toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  String _signedPercent(int value) => value > 0 ? '+$value%' : '$value%';

  void _showDetails(
    BuildContext context,
    String title,
    List<String> lines,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _AnalyticsPalette.panel,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _AnalyticsPalette.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    line,
                    style: TextStyle(
                      color: _AnalyticsPalette.muted,
                      fontSize: 13,
                      height: 1.35,
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

class LegacyKpiGrid extends StatelessWidget {
  const LegacyKpiGrid({super.key, required this.analytics});

  final AnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _KpiCard(
              width: width,
              label: 'Оплачено за месяц',
              value: analytics.actualMonthSpent.rub,
              detail: analytics.hasPreviousActualMonthSpent
                  ? '${_signedPercent(analytics.actualMonthChangePercent)} к прошлому месяцу'
                  : 'факт: нет прошлых списаний',
              detailColor: analytics.hasPreviousActualMonthSpent
                  ? analytics.actualMonthChangePercent > 0
                      ? _AnalyticsPalette.red
                      : _AnalyticsPalette.green
                  : _AnalyticsPalette.muted,
              accentColor: _AnalyticsPalette.accent,
              onTap: () => _showDetails(
                context,
                'Оплачено за месяц',
                [
                  'Факт за текущий месяц: ${analytics.actualMonthSpent.rub}',
                  analytics.hasPreviousActualMonthSpent
                      ? 'Факт за прошлый месяц: ${analytics.previousActualMonthSpent.rub}'
                      : 'За прошлый месяц фактических списаний нет.',
                  'Источник: транзакции списаний из локальной истории кошелька.',
                ],
              ),
            ),
            _KpiCard(
              width: width,
              label: 'План подписок',
              value: analytics.plannedMonthlyCost.rub,
              detail: 'активные подписки в месяц',
              detailColor: _AnalyticsPalette.muted,
              accentColor: _AnalyticsPalette.accent2,
              onTap: () => _showDetails(
                context,
                'План подписок',
                [
                  'Плановая нагрузка: ${analytics.plannedMonthlyCost.rub} в месяц.',
                  'Источник: активные подписки и их периоды оплаты.',
                  'Это не факт списания, а ожидаемый месячный план.',
                ],
              ),
            ),
            if (analytics.hasCurrentMonthCharges)
              _KpiCard(
                width: width,
                label: 'Средний чек',
                value: analytics.actualAverageCheck.rub,
                detail: analytics.hasPreviousAverageCheck
                    ? '${_signedPercent(analytics.actualAverageCheckChangePercent)} к прошлому месяцу'
                    : 'факт: текущие списания',
                detailColor: analytics.hasPreviousAverageCheck
                    ? analytics.actualAverageCheckChangePercent > 0
                        ? _AnalyticsPalette.red
                        : _AnalyticsPalette.green
                    : _AnalyticsPalette.muted,
                accentColor: _AnalyticsPalette.amber,
                onTap: () => _showDetails(
                  context,
                  'Средний чек',
                  [
                    'Факт среднего чека: ${analytics.actualAverageCheck.rub}',
                    analytics.hasPreviousAverageCheck
                        ? 'Прошлый месяц: ${analytics.previousActualAverageCheck.rub}'
                        : 'За прошлый месяц фактических чеков нет.',
                    'Формула: сумма реальных списаний / количество реальных списаний текущего месяца.',
                  ],
                ),
              ),
            _KpiCard(
              width: width,
              label: 'Прогноз года',
              value: analytics.yearlyForecast.rub,
              detail: 'план подписок × 12',
              detailColor: _AnalyticsPalette.muted,
              accentColor: _AnalyticsPalette.blue,
              onTap: () => _showDetails(
                context,
                'Прогноз года',
                [
                  'Прогноз: ${analytics.yearlyForecast.rub}',
                  'Формула: плановая стоимость активных подписок в месяц × 12.',
                ],
              ),
            ),
            if (analytics.recommendations.isNotEmpty)
              _KpiCard(
                width: width,
                label: 'Можно сэкономить',
                value: analytics.potentialSavings.rub,
                detail: 'в год',
                detailColor: _AnalyticsPalette.green,
                accentColor: _AnalyticsPalette.green,
                highlighted: true,
                onTap: () => _showDetails(
                  context,
                  'Можно сэкономить',
                  analytics.recommendations
                      .map(
                        (item) =>
                            '${item.subscription.name} -> ${item.alternativeName}: ${item.annualSavings.rub} в год',
                      )
                      .toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  String _signedPercent(int value) => value > 0 ? '+$value%' : '$value%';

  void _showDetails(
    BuildContext context,
    String title,
    List<String> lines,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _AnalyticsPalette.panel,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      showDragHandle: false,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _AnalyticsPalette.muted.withValues(alpha: 0.36),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  color: _AnalyticsPalette.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    line,
                    style: TextStyle(color: _AnalyticsPalette.muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.width,
    required this.label,
    required this.value,
    required this.detail,
    required this.detailColor,
    required this.accentColor,
    required this.onTap,
    this.highlighted = false,
  });

  final double width;
  final String label;
  final String value;
  final String detail;
  final Color detailColor;
  final Color accentColor;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 118,
      child: _AnalyticsCard(
        onTap: onTap,
        backgroundColor: highlighted
            ? _AnalyticsPalette.savingsPanel
            : _AnalyticsPalette.panel,
        borderColor: highlighted
            ? _AnalyticsPalette.savingsBorder
            : _AnalyticsPalette.border,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _AnalyticsPalette.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  color: _AnalyticsPalette.text,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const Spacer(),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: detailColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveAnalyticsGrid extends StatelessWidget {
  const _ResponsiveAnalyticsGrid({
    required this.left,
    required this.right,
  });

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: left),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: right),
            ],
          );
        }
        return Column(
          children: [
            left,
            const SizedBox(height: 12),
            right,
          ],
        );
      },
    );
  }
}

class _SpendingBarChartCard extends StatelessWidget {
  const _SpendingBarChartCard({required this.analytics});

  final AnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    final maxValue = analytics.months.fold<double>(
      0,
      (value, month) => math.max(value, month.amount),
    );
    final normalizedMax = maxValue <= 0 ? 1.0 : maxValue;
    return _AnalyticsCard(
      minHeight: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            title: 'Динамика трат',
            trailing: _LegendPair(),
          ),
          const SizedBox(height: 12),
          for (final month in analytics.months)
            _MonthBarRow(
              month: month,
              normalizedMax: normalizedMax,
              onTap: () => _showMonthDetails(context, month),
            ),
        ],
      ),
    );
  }

  void _showMonthDetails(BuildContext context, AnalyticsMonthSpend month) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _AnalyticsPalette.panel,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'В ${_monthTitle(month.monthStart)} потрачено ${month.amount.rub}',
                style: TextStyle(
                  color: _AnalyticsPalette.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Активные подписки',
                style: TextStyle(
                  color: _AnalyticsPalette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (month.subscriptions.isEmpty)
                Text(
                  'Нет связанных подписок',
                  style: TextStyle(color: _AnalyticsPalette.muted),
                )
              else
                for (final subscription in month.subscriptions.take(8))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            subscription.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _AnalyticsPalette.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          subscription.amount.rub,
                          style: TextStyle(
                            color: _AnalyticsPalette.text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthTitle(DateTime month) {
    const labels = [
      'январе',
      'феврале',
      'марте',
      'апреле',
      'мае',
      'июне',
      'июле',
      'августе',
      'сентябре',
      'октябре',
      'ноябре',
      'декабре',
    ];
    return '${labels[month.month - 1]} ${month.year}';
  }
}

class _MonthBarRow extends StatelessWidget {
  const _MonthBarRow({
    required this.month,
    required this.normalizedMax,
    required this.onTap,
  });

  final AnalyticsMonthSpend month;
  final double normalizedMax;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final factor = (month.amount / normalizedMax).clamp(0.04, 1.0).toDouble();
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Text(
                month.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _AnalyticsPalette.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  children: [
                    Container(
                      height: 12,
                      color: _AnalyticsPalette.progressTrack,
                    ),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: factor,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: _AnalyticsPalette.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: Text(
                month.amount.rub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: _AnalyticsPalette.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegacySpendingChartCard extends StatelessWidget {
  const LegacySpendingChartCard({super.key, required this.analytics});

  final AnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      minHeight: 214,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            title: 'Динамика трат',
            trailing: _LegendPair(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 136,
            child: CustomPaint(
              painter: _SpendingLinePainter(analytics.months),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              for (final month in analytics.months)
                Expanded(
                  child: Text(
                    month.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _AnalyticsPalette.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendPair extends StatelessWidget {
  const _LegendPair();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDot(color: _AnalyticsPalette.accent, label: 'факт'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: _AnalyticsPalette.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SpendingLinePainter extends CustomPainter {
  _SpendingLinePainter(this.months);

  final List<AnalyticsMonthSpend> months;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _AnalyticsPalette.chartGrid
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (i + 1) / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (months.isEmpty) return;

    final maxValue = months.fold<double>(
      0,
      (maxValue, month) => math.max(maxValue, month.amount),
    );
    final normalizedMax = maxValue <= 0 ? 1 : maxValue;
    final spacing = months.length == 1 ? 0.0 : size.width / (months.length - 1);
    final points = <Offset>[];
    for (var i = 0; i < months.length; i++) {
      final x = months.length == 1 ? size.width / 2 : spacing * i;
      final normalized = months[i].amount / normalizedMax;
      final y = size.height - normalized * size.height * 0.72 - 14;
      points.add(Offset(x, y.clamp(8.0, size.height - 8)));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final point = points[i];
      final controlX = (previous.dx + point.dx) / 2;
      linePath.cubicTo(
        controlX,
        previous.dy,
        controlX,
        point.dy,
        point.dx,
        point.dy,
      );
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _AnalyticsPalette.accent.withValues(alpha: 0.34),
            _AnalyticsPalette.accent.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = _AnalyticsPalette.accent
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 3,
    );
    for (final point in points) {
      canvas.drawCircle(point, 3.2, Paint()..color = _AnalyticsPalette.accent);
      canvas.drawCircle(
        point,
        5.4,
        Paint()
          ..color = _AnalyticsPalette.accent.withValues(alpha: 0.20)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpendingLinePainter oldDelegate) {
    return oldDelegate.months != months;
  }
}

class _CategoryDonutCard extends StatelessWidget {
  const _CategoryDonutCard({required this.analytics});

  final AnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    final categories = analytics.categories.take(5).toList();
    return _AnalyticsCard(
      minHeight: 214,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: 'План по категориям'),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 138,
              height: 138,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    painter: _DonutPainter(categories),
                    child: const SizedBox.expand(),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        analytics.plannedMonthlyCost.rub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _AnalyticsPalette.text,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'план/мес.',
                        style: TextStyle(
                          color: _AnalyticsPalette.muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (categories.isEmpty)
            Text(
              'План появится после добавления активных подписок',
              style: TextStyle(color: _AnalyticsPalette.muted, fontSize: 12),
            )
          else
            for (var i = 0; i < categories.length; i++)
              _CategoryLegendRow(
                color: _categoryColors[i % _categoryColors.length],
                category: categories[i],
              ),
        ],
      ),
    );
  }
}

List<Color> get _categoryColors => [
      _AnalyticsPalette.accent,
      _AnalyticsPalette.accent2,
      _AnalyticsPalette.green,
      _AnalyticsPalette.amber,
      _AnalyticsPalette.blue,
    ];

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.categories);

  final List<AnalyticsCategorySpend> categories;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = radius * 0.30;
    final background = Paint()
      ..color = _AnalyticsPalette.progressTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, background);
    if (categories.isEmpty) return;

    var start = -math.pi / 2;
    for (var i = 0; i < categories.length; i++) {
      final sweep = math.pi * 2 * (categories[i].percent / 100);
      final paint = Paint()
        ..color = _categoryColors[i % _categoryColors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.categories != categories;
  }
}

class _CategoryLegendRow extends StatelessWidget {
  const _CategoryLegendRow({
    required this.color,
    required this.category,
  });

  final Color color;
  final AnalyticsCategorySpend category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: () => context.push(
          Uri(
            path: '/subscriptions',
            queryParameters: {'category': category.name},
          ).toString(),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _AnalyticsPalette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  category.amount.rub,
                  style: TextStyle(
                    color: _AnalyticsPalette.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${category.percent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: _AnalyticsPalette.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      category.changePercent > 0
                          ? Icons.arrow_upward
                          : category.changePercent < 0
                              ? Icons.arrow_downward
                              : Icons.remove,
                      size: 10,
                      color: category.changePercent > 0
                          ? _AnalyticsPalette.red
                          : category.changePercent < 0
                              ? _AnalyticsPalette.green
                              : _AnalyticsPalette.muted,
                    ),
                    Text(
                      '${category.changePercent.abs()}%',
                      style: TextStyle(
                        color: category.changePercent > 0
                            ? _AnalyticsPalette.red
                            : category.changePercent < 0
                                ? _AnalyticsPalette.green
                                : _AnalyticsPalette.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingPanel extends StatelessWidget {
  const _UpcomingPanel({
    required this.subscriptions,
    required this.onOpenAll,
    required this.onSubscriptionTap,
  });

  final List<SubscriptionData> subscriptions;
  final VoidCallback onOpenAll;
  final ValueChanged<int> onSubscriptionTap;

  @override
  Widget build(BuildContext context) {
    final visible = subscriptions.take(3).toList();
    return _AnalyticsCard(
      minHeight: 142,
      borderColor: _AnalyticsPalette.warningBorder,
      backgroundColor: _AnalyticsPalette.warningPanel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: 'Ближайшие списания',
            actionLabel: 'Все',
            onAction: onOpenAll,
          ),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            Text(
              'Списаний пока нет',
              style: TextStyle(color: _AnalyticsPalette.muted),
            )
          else
            for (final subscription in visible)
              _CompactSubscriptionRow(
                subscription: subscription,
                onTap: () => onSubscriptionTap(subscription.id),
              ),
        ],
      ),
    );
  }
}

class _CompactSubscriptionRow extends StatelessWidget {
  const _CompactSubscriptionRow({
    required this.subscription,
    required this.onTap,
  });

  final SubscriptionData subscription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final payment = DateTime(
      subscription.nextPaymentDate.year,
      subscription.nextPaymentDate.month,
      subscription.nextPaymentDate.day,
    );
    final isSoon = payment.difference(today).inDays <= 3;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSoon
            ? _AnalyticsPalette.red.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Color(subscription.iconColor),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      subscription.iconLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _AnalyticsPalette.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subscription.nextPaymentDate.relativeToNow(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _AnalyticsPalette.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  subscription.amount.rub,
                  style: TextStyle(
                    color: _AnalyticsPalette.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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

class _TrialPanel extends StatelessWidget {
  const _TrialPanel({
    required this.trials,
    required this.onToggleAutoCancel,
    required this.onSubscriptionTap,
  });

  final List<SubscriptionData> trials;
  final void Function(int id, bool value) onToggleAutoCancel;
  final ValueChanged<int> onSubscriptionTap;

  @override
  Widget build(BuildContext context) {
    final visible = trials.take(3).toList();
    return _AnalyticsCard(
      minHeight: 142,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: 'Пробные периоды'),
          const SizedBox(height: 10),
          for (final subscription in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => onSubscriptionTap(subscription.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subscription.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _AnalyticsPalette.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _trialText(subscription),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _AnalyticsPalette.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Switch(
                    value: subscription.cancelAfterTrial,
                    activeThumbColor: _AnalyticsPalette.green,
                    onChanged: (value) =>
                        onToggleAutoCancel(subscription.id, value),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _trialText(SubscriptionData subscription) {
    final end = subscription.trialEndAt!;
    final daysLeft = end.difference(DateTime.now()).inDays + 1;
    final days = daysLeft < 1 ? 0 : daysLeft;
    return '$days дн. осталось • до ${end.dayMonth}';
  }
}

class _InactivePanel extends StatelessWidget {
  const _InactivePanel({
    required this.insights,
    required this.onArchive,
    required this.onHide,
    required this.onSubscriptionTap,
  });

  final List<InactiveSubscriptionInsight> insights;
  final ValueChanged<int> onArchive;
  final ValueChanged<int> onHide;
  final ValueChanged<int> onSubscriptionTap;

  @override
  Widget build(BuildContext context) {
    final visible = insights.take(3).toList();
    return _AnalyticsCard(
      minHeight: 142,
      borderColor: _AnalyticsPalette.warningBorder,
      backgroundColor: _AnalyticsPalette.warningPanel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: 'Неиспользуемые'),
          const SizedBox(height: 10),
          for (final insight in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => onSubscriptionTap(insight.subscription.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            insight.subscription.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _AnalyticsPalette.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '${insight.inactiveDays} дн.',
                          style: TextStyle(
                            color: _AnalyticsPalette.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _SmallPillButton(
                        label: 'Отменить',
                        icon: Icons.archive_outlined,
                        color: _AnalyticsPalette.red,
                        onTap: () => onArchive(insight.subscription.id),
                      ),
                      const SizedBox(width: 8),
                      _SmallPillButton(
                        label: 'Не предлагать',
                        icon: Icons.visibility_off_outlined,
                        color: _AnalyticsPalette.muted,
                        onTap: () => onHide(insight.subscription.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecommendationPanelV2 extends StatelessWidget {
  const _RecommendationPanelV2({
    required this.analytics,
    required this.onHide,
  });

  final AnalyticsSnapshot analytics;
  final ValueChanged<String> onHide;

  @override
  Widget build(BuildContext context) {
    final recommendations = analytics.recommendations.take(3).toList();
    return _AnalyticsCard(
      minHeight: 142,
      borderColor: _AnalyticsPalette.recommendationBorder,
      backgroundColor: _AnalyticsPalette.recommendationPanel,
      child: recommendations.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelHeader(title: 'Рекомендации'),
                const SizedBox(height: 12),
                Text(
                  'Подходящих аналогов пока нет',
                  style: TextStyle(
                    color: _AnalyticsPalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelHeader(title: 'Рекомендации'),
                const SizedBox(height: 12),
                for (final recommendation in recommendations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _AnalyticsPalette.accent
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.lightbulb,
                                color: _AnalyticsPalette.accent,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${recommendation.subscription.name} -> ${recommendation.alternativeName}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _AnalyticsPalette.text,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Экономия ${recommendation.annualSavings.rub} в год',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _AnalyticsPalette.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _SmallPillButton(
                              label: 'Скрыть',
                              icon: Icons.visibility_off_outlined,
                              color: _AnalyticsPalette.muted,
                              onTap: () => onHide(recommendation.key),
                            ),
                            const SizedBox(width: 8),
                            _SmallPillButton(
                              label: 'Перейти',
                              icon: Icons.open_in_new,
                              color: _AnalyticsPalette.accent,
                              onTap: () => _openRecommendationUrl(
                                  context, recommendation),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _openRecommendationUrl(
    BuildContext context,
    SavingsRecommendation recommendation,
  ) async {
    await Clipboard.setData(ClipboardData(text: recommendation.url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Ссылка скопирована. Открытие URL подключается отдельно.'),
      ),
    );
  }
}

class LegacyRecommendationPanel extends StatelessWidget {
  const LegacyRecommendationPanel({
    super.key,
    required this.analytics,
    required this.onHide,
  });

  final AnalyticsSnapshot analytics;
  final ValueChanged<String> onHide;

  @override
  Widget build(BuildContext context) {
    final recommendation = analytics.recommendations.isEmpty
        ? null
        : analytics.recommendations.first;
    return _AnalyticsCard(
      minHeight: 142,
      borderColor: _AnalyticsPalette.recommendationBorder,
      backgroundColor: _AnalyticsPalette.recommendationPanel,
      child: recommendation == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelHeader(title: 'Рекомендация'),
                const SizedBox(height: 12),
                Text(
                  'Подходящих аналогов пока нет',
                  style: TextStyle(
                    color: _AnalyticsPalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PanelHeader(
                  title: 'Рекомендация',
                  actionLabel: 'Скрыть',
                  onAction: () => onHide(recommendation.key),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _AnalyticsPalette.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.lightbulb,
                        color: _AnalyticsPalette.accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${recommendation.subscription.name} -> ${recommendation.alternativeName}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _AnalyticsPalette.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Экономия ${recommendation.annualSavings.rub} в год',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _AnalyticsPalette.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _SmallPillButton(
                    label: 'Перейти',
                    icon: Icons.open_in_new,
                    color: _AnalyticsPalette.accent,
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: recommendation.url),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ссылка скопирована')),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _ForecastPanel extends StatelessWidget {
  const _ForecastPanel({required this.analytics});

  final AnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      backgroundColor: _AnalyticsPalette.forecastPanel,
      borderColor: _AnalyticsPalette.forecastBorder,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _AnalyticsPalette.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.trending_up,
              color: _AnalyticsPalette.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'При текущем плане подписок вы запланировали ',
                style: TextStyle(
                  color: _AnalyticsPalette.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(
                    text: analytics.yearlyForecast.rub,
                    style: TextStyle(color: _AnalyticsPalette.green),
                  ),
                  const TextSpan(text: ' за год'),
                  if (analytics.potentialSavings > 0)
                    TextSpan(
                      text:
                          ', но сможете сэкономить ${analytics.potentialSavings.rub}.',
                      style: TextStyle(color: _AnalyticsPalette.green),
                    ),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetPanel extends StatelessWidget {
  const _BudgetPanel({required this.analytics});

  final AnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    final budget = analytics.monthlyBudget!;
    final progressColor = analytics.isBudgetExceeded
        ? _AnalyticsPalette.red
        : _AnalyticsPalette.green;
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: 'Личный лимит',
            actionLabel: 'Настроить',
            onAction: () => context.push('/settings'),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: analytics.budgetProgress,
              color: progressColor,
              backgroundColor: _AnalyticsPalette.progressTrack,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            analytics.isBudgetExceeded
                ? 'План выше лимита на ${analytics.budgetOverrun.rub}'
                : 'План: ${analytics.plannedMonthlyCost.rub} из ${budget.rub}',
            style: TextStyle(
              color: progressColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletPanel extends StatelessWidget {
  const _WalletPanel({
    required this.wallet,
    required this.monthlyCost,
    required this.onTap,
  });

  final WalletState wallet;
  final double monthlyCost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final monthsCovered =
        monthlyCost > 0 ? (wallet.balance / monthlyCost).floor() : 0;
    return _AnalyticsCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.walletBlue.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: AppColors.walletBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Кошелек: ${wallet.balance.rub}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _AnalyticsPalette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Хватит примерно на $monthsCovered мес. подписок',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _AnalyticsPalette.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: _AnalyticsPalette.muted,
          ),
        ],
      ),
    );
  }
}

class _QuickActionStripV2 extends StatelessWidget {
  const _QuickActionStripV2({
    required this.onAdd,
    required this.onCalendar,
    required this.onHistory,
    required this.onPriceHistory,
    required this.onExport,
  });

  final VoidCallback onAdd;
  final VoidCallback onCalendar;
  final VoidCallback onHistory;
  final VoidCallback onPriceHistory;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 9.0;
        final itemWidth = (constraints.maxWidth - spacing * 2) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: _ActionTile(
                icon: Icons.add_circle_outline,
                label: 'Добавить',
                onTap: onAdd,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _ActionTile(
                icon: Icons.calendar_month_outlined,
                label: 'Календарь',
                onTap: onCalendar,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _ActionTile(
                icon: Icons.history,
                label: 'Списания',
                onTap: onHistory,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _ActionTile(
                icon: Icons.price_change_outlined,
                label: 'Цены',
                onTap: onPriceHistory,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _ActionTile(
                icon: Icons.download,
                label: 'Экспорт',
                onTap: onExport,
              ),
            ),
          ],
        );
      },
    );
  }
}

class LegacyQuickActionStrip extends StatelessWidget {
  const LegacyQuickActionStrip({
    super.key,
    required this.onAdd,
    required this.onCalendar,
    required this.onHistory,
    required this.onExport,
  });

  final VoidCallback onAdd;
  final VoidCallback onCalendar;
  final VoidCallback onHistory;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.add_circle_outline,
            label: 'Добавить',
            onTap: onAdd,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _ActionTile(
            icon: Icons.calendar_month_outlined,
            label: 'Календарь',
            onTap: onCalendar,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _ActionTile(
            icon: Icons.history,
            label: 'История',
            onTap: onHistory,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _ActionTile(
            icon: Icons.download,
            label: 'Экспорт',
            onTap: onExport,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _AnalyticsPalette.accent, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _AnalyticsPalette.text,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    this.trailing,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _AnalyticsPalette.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (trailing != null) trailing!,
        if (actionLabel != null && onAction != null)
          _PlainAction(label: actionLabel!, onTap: onAction!),
      ],
    );
  }
}

class _PlainAction extends StatelessWidget {
  const _PlainAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: _AnalyticsPalette.muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SmallPillButton extends StatelessWidget {
  const _SmallPillButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.backgroundColor,
    this.borderColor,
    this.minHeight,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? _AnalyticsPalette.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? _AnalyticsPalette.border),
        boxShadow: [
          BoxShadow(
            color: _AnalyticsPalette.shadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
