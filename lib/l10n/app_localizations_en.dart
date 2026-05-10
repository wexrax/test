// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Subscriptions';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Start';

  @override
  String get phoneTitle => 'Enter phone number';

  @override
  String get phoneHint => '+1 (999) 999-9999';

  @override
  String get agreeToTerms => 'I agree to the terms';

  @override
  String get codeTitle => 'Enter SMS code';

  @override
  String get demoCode => '123456';

  @override
  String get loginButton => 'Login';

  @override
  String get logoutButton => 'Logout';

  @override
  String get greeting => 'Good afternoon 👋';

  @override
  String get yourBudget => 'Your budget';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get monthlySpending => 'Monthly spending';

  @override
  String subscriptionCount(Object count) {
    return 'Subscriptions: $count';
  }

  @override
  String yearlySpending(Object amount) {
    return 'Yearly: $amount';
  }

  @override
  String averageCheck(Object amount) {
    return 'Average: $amount';
  }

  @override
  String nextPayment(Object date) {
    return 'Next payment: $date';
  }

  @override
  String walletBalance(Object amount) {
    return 'Balance: $amount';
  }

  @override
  String walletSufficientFor(Object months) {
    return 'Enough for $months months';
  }

  @override
  String get vsMarket => 'vs market (2500 ₽)';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get addSubscription => 'Add';

  @override
  String get addSubscriptionTitle => 'Add subscription';

  @override
  String get customSubscriptionTitle => 'Custom subscription';

  @override
  String get customSubscriptionSubtitle =>
      'Add any service with your own price and period';

  @override
  String get customSubscriptionNameHint => 'e.g. Telegram Premium';

  @override
  String get customSubscriptionCategoryHint => 'e.g. Communication';

  @override
  String get customSubscriptionNameRequired => 'Enter a subscription name';

  @override
  String get customSubscriptionCategoryRequired => 'Enter a category';

  @override
  String get customSubscriptionPriceRequired => 'Enter a price';

  @override
  String get customSubscriptionPriceInvalid => 'Enter an amount greater than 0';

  @override
  String get periodWeekly => 'Weekly';

  @override
  String get firstPaymentDate => 'First payment';

  @override
  String get trialPeriod => 'Trial period';

  @override
  String get trialEnd => 'Trial ends';

  @override
  String get cancelAfterTrial => 'Cancel after trial';

  @override
  String subscriptionAdded(Object name) {
    return 'Subscription "$name" added';
  }

  @override
  String get calendar => 'Calendar';

  @override
  String get history => 'History';

  @override
  String get export => 'Export';

  @override
  String get upcomingPayments => 'Upcoming payments';

  @override
  String get categories => 'Categories';

  @override
  String get activeSubscriptions => 'Active';

  @override
  String get archivedSubscriptions => 'Archive';

  @override
  String get searchHint => 'Search by name';

  @override
  String get detailTitle => 'Subscription';

  @override
  String get category => 'Category';

  @override
  String get period => 'Period';

  @override
  String get status => 'Status';

  @override
  String get yearlyAmount => 'Yearly amount';

  @override
  String get markAsPaid => 'I already paid';

  @override
  String get edit => 'Edit';

  @override
  String get cancelDelete => 'Cancel / Delete';

  @override
  String get cancelSubscription => 'Cancel subscription';

  @override
  String get restoreSubscription => 'Restore';

  @override
  String get deleteSubscription => 'Delete';

  @override
  String get cancelSubscriptionTitle => 'Cancel subscription?';

  @override
  String get cancelSubscriptionMessage =>
      'The subscription will move to the archive.';

  @override
  String get deleteSubscriptionTitle => 'Delete subscription?';

  @override
  String get deleteSubscriptionMessage =>
      'The subscription will be permanently deleted.';

  @override
  String get calendarTitle => 'Payment calendar';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String inDays(Object days) {
    return 'In $days days';
  }

  @override
  String get walletTitle => 'Wallet';

  @override
  String get topUp => 'Top up';

  @override
  String get autoTopUp => 'Auto';

  @override
  String get autoTopUpSettings => 'Auto top-up settings';

  @override
  String get threshold => 'Threshold';

  @override
  String get amount => 'Amount';

  @override
  String get transactionHistory => 'Recent transactions';

  @override
  String get topUpModalTitle => 'Top up wallet';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get historyTitle => 'Payment history';

  @override
  String get filterPeriod => 'Period';

  @override
  String get month => 'Month';

  @override
  String get quarter => 'Quarter';

  @override
  String get year => 'Year';

  @override
  String totalForPeriod(Object amount) {
    return 'Total for period: $amount';
  }

  @override
  String get merchantTitle => 'My merchant subscriptions';

  @override
  String get createMerchant => 'Create subscription';

  @override
  String get name => 'Name';

  @override
  String get description => 'Description';

  @override
  String get price => 'Price';

  @override
  String get periodMonthly => 'Monthly';

  @override
  String get periodYearly => 'Yearly';

  @override
  String get link => 'Link';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get minWithdraw => 'Minimum 100 ₽';

  @override
  String subscribersCount(Object count) {
    return 'Subscribers: $count';
  }

  @override
  String earned(Object amount) {
    return 'Earned: $amount';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileAccountEyebrow => 'Your account';

  @override
  String get profilePremiumEyebrow => 'Financial profile';

  @override
  String get profileDefaultName => 'Good user';

  @override
  String get profileSectionsTitle => 'Sections';

  @override
  String get profileActionsTitle => 'Control center';

  @override
  String get profileActiveStat => 'active';

  @override
  String get profileMonthlyPlanStat => 'plan/mo.';

  @override
  String get profileWalletStat => 'wallet';

  @override
  String get profileExportTitle => 'Export';

  @override
  String get profileMerchantSubtitle => 'Create and sell';

  @override
  String get profileWalletSubtitle => 'Balance and auto top-up';

  @override
  String get profileHistorySubtitle => 'All charges';

  @override
  String get profileExportSubtitle => 'Download CSV';

  @override
  String get profileSettingsSubtitle => 'Notifications and security';

  @override
  String get phone => 'Phone';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get notify7days => '7 days before';

  @override
  String get notify3days => '3 days before';

  @override
  String get notify1day => '1 day before';

  @override
  String get faceID => 'Face ID / Touch ID';

  @override
  String get timezone => 'Time zone';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get dataExported => 'Data exported';

  @override
  String get done => 'Done';

  @override
  String get paidSuccess => 'Payment recorded';

  @override
  String get insufficientFunds => 'Insufficient funds';

  @override
  String get archiveTimer => 'Archive timer';

  @override
  String archiveScheduledAt(Object date) {
    return 'Archives at: $date';
  }

  @override
  String get clearArchiveTimer => 'Reset timer';

  @override
  String get archiveTimerSaved => 'Archive timer saved';

  @override
  String get archiveTimerCleared => 'Archive timer reset';

  @override
  String get notificationPermissionStatus => 'Notification permission';

  @override
  String get notificationPermissionGranted => 'Allowed';

  @override
  String get notificationPermissionDenied => 'Denied';

  @override
  String get notificationPermissionUnknown => 'Not requested yet';

  @override
  String get notificationPermissionUnsupported =>
      'Not supported on this device';

  @override
  String get requestNotificationsPermission => 'Allow notifications';

  @override
  String get testNotification => 'Test notification';

  @override
  String get testNotificationSent => 'Test notification sent';

  @override
  String get refreshNotificationSchedule => 'Refresh schedule';

  @override
  String get notificationScheduleRefreshed => 'Notification schedule refreshed';

  @override
  String get analyticsTotalMonth => 'Total this month';

  @override
  String get analyticsSpendingDynamics => 'Spending dynamics';

  @override
  String get analyticsTrials => 'Trials';

  @override
  String get analyticsInactiveSubscriptions => 'Unused subscriptions';

  @override
  String get analyticsPriceHistoryTitle => 'Price change history';

  @override
  String get subscriptionMarkUsed => 'Used it';

  @override
  String get subscriptionUsageMarked => 'Usage recorded';

  @override
  String get subscriptionEditPrice => 'Change price';

  @override
  String get subscriptionTrialUntil => 'Trial until';

  @override
  String notificationScheduleSummary(Object count, Object days) {
    return '$count planned, days: $days';
  }
}
