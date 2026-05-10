import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'My Subscriptions'**
  String get appTitle;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// No description provided for @phoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get phoneTitle;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'+1 (999) 999-9999'**
  String get phoneHint;

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the terms'**
  String get agreeToTerms;

  /// No description provided for @codeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter SMS code'**
  String get codeTitle;

  /// No description provided for @demoCode.
  ///
  /// In en, this message translates to:
  /// **'123456'**
  String get demoCode;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon 👋'**
  String get greeting;

  /// No description provided for @yourBudget.
  ///
  /// In en, this message translates to:
  /// **'Your budget'**
  String get yourBudget;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @monthlySpending.
  ///
  /// In en, this message translates to:
  /// **'Monthly spending'**
  String get monthlySpending;

  /// No description provided for @subscriptionCount.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions: {count}'**
  String subscriptionCount(Object count);

  /// No description provided for @yearlySpending.
  ///
  /// In en, this message translates to:
  /// **'Yearly: {amount}'**
  String yearlySpending(Object amount);

  /// No description provided for @averageCheck.
  ///
  /// In en, this message translates to:
  /// **'Average: {amount}'**
  String averageCheck(Object amount);

  /// No description provided for @nextPayment.
  ///
  /// In en, this message translates to:
  /// **'Next payment: {date}'**
  String nextPayment(Object date);

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance: {amount}'**
  String walletBalance(Object amount);

  /// No description provided for @walletSufficientFor.
  ///
  /// In en, this message translates to:
  /// **'Enough for {months} months'**
  String walletSufficientFor(Object months);

  /// No description provided for @vsMarket.
  ///
  /// In en, this message translates to:
  /// **'vs market (2500 ₽)'**
  String get vsMarket;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @addSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addSubscription;

  /// No description provided for @addSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get addSubscriptionTitle;

  /// No description provided for @customSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom subscription'**
  String get customSubscriptionTitle;

  /// No description provided for @customSubscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add any service with your own price and period'**
  String get customSubscriptionSubtitle;

  /// No description provided for @customSubscriptionNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Telegram Premium'**
  String get customSubscriptionNameHint;

  /// No description provided for @customSubscriptionCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Communication'**
  String get customSubscriptionCategoryHint;

  /// No description provided for @customSubscriptionNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a subscription name'**
  String get customSubscriptionNameRequired;

  /// No description provided for @customSubscriptionCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a category'**
  String get customSubscriptionCategoryRequired;

  /// No description provided for @customSubscriptionPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a price'**
  String get customSubscriptionPriceRequired;

  /// No description provided for @customSubscriptionPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than 0'**
  String get customSubscriptionPriceInvalid;

  /// No description provided for @periodWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get periodWeekly;

  /// No description provided for @firstPaymentDate.
  ///
  /// In en, this message translates to:
  /// **'First payment'**
  String get firstPaymentDate;

  /// No description provided for @trialPeriod.
  ///
  /// In en, this message translates to:
  /// **'Trial period'**
  String get trialPeriod;

  /// No description provided for @trialEnd.
  ///
  /// In en, this message translates to:
  /// **'Trial ends'**
  String get trialEnd;

  /// No description provided for @cancelAfterTrial.
  ///
  /// In en, this message translates to:
  /// **'Cancel after trial'**
  String get cancelAfterTrial;

  /// No description provided for @subscriptionAdded.
  ///
  /// In en, this message translates to:
  /// **'Subscription "{name}" added'**
  String subscriptionAdded(Object name);

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @upcomingPayments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming payments'**
  String get upcomingPayments;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @activeSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeSubscriptions;

  /// No description provided for @archivedSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archivedSubscriptions;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchHint;

  /// No description provided for @detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get detailTitle;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @yearlyAmount.
  ///
  /// In en, this message translates to:
  /// **'Yearly amount'**
  String get yearlyAmount;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'I already paid'**
  String get markAsPaid;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @cancelDelete.
  ///
  /// In en, this message translates to:
  /// **'Cancel / Delete'**
  String get cancelDelete;

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get cancelSubscription;

  /// No description provided for @restoreSubscription.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreSubscription;

  /// No description provided for @deleteSubscription.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteSubscription;

  /// No description provided for @cancelSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription?'**
  String get cancelSubscriptionTitle;

  /// No description provided for @cancelSubscriptionMessage.
  ///
  /// In en, this message translates to:
  /// **'The subscription will move to the archive.'**
  String get cancelSubscriptionMessage;

  /// No description provided for @deleteSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete subscription?'**
  String get deleteSubscriptionTitle;

  /// No description provided for @deleteSubscriptionMessage.
  ///
  /// In en, this message translates to:
  /// **'The subscription will be permanently deleted.'**
  String get deleteSubscriptionMessage;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment calendar'**
  String get calendarTitle;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String inDays(Object days);

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletTitle;

  /// No description provided for @topUp.
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get topUp;

  /// No description provided for @autoTopUp.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get autoTopUp;

  /// No description provided for @autoTopUpSettings.
  ///
  /// In en, this message translates to:
  /// **'Auto top-up settings'**
  String get autoTopUpSettings;

  /// No description provided for @threshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get threshold;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get transactionHistory;

  /// No description provided for @topUpModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Top up wallet'**
  String get topUpModalTitle;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get historyTitle;

  /// No description provided for @filterPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get filterPeriod;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @quarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get quarter;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @totalForPeriod.
  ///
  /// In en, this message translates to:
  /// **'Total for period: {amount}'**
  String totalForPeriod(Object amount);

  /// No description provided for @merchantTitle.
  ///
  /// In en, this message translates to:
  /// **'My merchant subscriptions'**
  String get merchantTitle;

  /// No description provided for @createMerchant.
  ///
  /// In en, this message translates to:
  /// **'Create subscription'**
  String get createMerchant;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @periodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get periodMonthly;

  /// No description provided for @periodYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get periodYearly;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @minWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Minimum 100 ₽'**
  String get minWithdraw;

  /// No description provided for @subscribersCount.
  ///
  /// In en, this message translates to:
  /// **'Subscribers: {count}'**
  String subscribersCount(Object count);

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned: {amount}'**
  String earned(Object amount);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileAccountEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get profileAccountEyebrow;

  /// No description provided for @profilePremiumEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Financial profile'**
  String get profilePremiumEyebrow;

  /// No description provided for @profileDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Good user'**
  String get profileDefaultName;

  /// No description provided for @profileSectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get profileSectionsTitle;

  /// No description provided for @profileActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Control center'**
  String get profileActionsTitle;

  /// No description provided for @profileActiveStat.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get profileActiveStat;

  /// No description provided for @profileMonthlyPlanStat.
  ///
  /// In en, this message translates to:
  /// **'plan/mo.'**
  String get profileMonthlyPlanStat;

  /// No description provided for @profileWalletStat.
  ///
  /// In en, this message translates to:
  /// **'wallet'**
  String get profileWalletStat;

  /// No description provided for @profileExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get profileExportTitle;

  /// No description provided for @profileMerchantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create and sell'**
  String get profileMerchantSubtitle;

  /// No description provided for @profileWalletSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Balance and auto top-up'**
  String get profileWalletSubtitle;

  /// No description provided for @profileHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'All charges'**
  String get profileHistorySubtitle;

  /// No description provided for @profileExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download CSV'**
  String get profileExportSubtitle;

  /// No description provided for @profileSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications and security'**
  String get profileSettingsSubtitle;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notify7days.
  ///
  /// In en, this message translates to:
  /// **'7 days before'**
  String get notify7days;

  /// No description provided for @notify3days.
  ///
  /// In en, this message translates to:
  /// **'3 days before'**
  String get notify3days;

  /// No description provided for @notify1day.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get notify1day;

  /// No description provided for @faceID.
  ///
  /// In en, this message translates to:
  /// **'Face ID / Touch ID'**
  String get faceID;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get timezone;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @dataExported.
  ///
  /// In en, this message translates to:
  /// **'Data exported'**
  String get dataExported;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @paidSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get paidSuccess;

  /// No description provided for @insufficientFunds.
  ///
  /// In en, this message translates to:
  /// **'Insufficient funds'**
  String get insufficientFunds;

  /// No description provided for @archiveTimer.
  ///
  /// In en, this message translates to:
  /// **'Archive timer'**
  String get archiveTimer;

  /// No description provided for @archiveScheduledAt.
  ///
  /// In en, this message translates to:
  /// **'Archives at: {date}'**
  String archiveScheduledAt(Object date);

  /// No description provided for @clearArchiveTimer.
  ///
  /// In en, this message translates to:
  /// **'Reset timer'**
  String get clearArchiveTimer;

  /// No description provided for @archiveTimerSaved.
  ///
  /// In en, this message translates to:
  /// **'Archive timer saved'**
  String get archiveTimerSaved;

  /// No description provided for @archiveTimerCleared.
  ///
  /// In en, this message translates to:
  /// **'Archive timer reset'**
  String get archiveTimerCleared;

  /// No description provided for @notificationPermissionStatus.
  ///
  /// In en, this message translates to:
  /// **'Notification permission'**
  String get notificationPermissionStatus;

  /// No description provided for @notificationPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get notificationPermissionGranted;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get notificationPermissionDenied;

  /// No description provided for @notificationPermissionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not requested yet'**
  String get notificationPermissionUnknown;

  /// No description provided for @notificationPermissionUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Not supported on this device'**
  String get notificationPermissionUnsupported;

  /// No description provided for @requestNotificationsPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get requestNotificationsPermission;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test notification'**
  String get testNotification;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent'**
  String get testNotificationSent;

  /// No description provided for @refreshNotificationSchedule.
  ///
  /// In en, this message translates to:
  /// **'Refresh schedule'**
  String get refreshNotificationSchedule;

  /// No description provided for @notificationScheduleRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Notification schedule refreshed'**
  String get notificationScheduleRefreshed;

  /// No description provided for @analyticsTotalMonth.
  ///
  /// In en, this message translates to:
  /// **'Total this month'**
  String get analyticsTotalMonth;

  /// No description provided for @analyticsSpendingDynamics.
  ///
  /// In en, this message translates to:
  /// **'Spending dynamics'**
  String get analyticsSpendingDynamics;

  /// No description provided for @analyticsTrials.
  ///
  /// In en, this message translates to:
  /// **'Trials'**
  String get analyticsTrials;

  /// No description provided for @analyticsInactiveSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Unused subscriptions'**
  String get analyticsInactiveSubscriptions;

  /// No description provided for @analyticsPriceHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Price change history'**
  String get analyticsPriceHistoryTitle;

  /// No description provided for @subscriptionMarkUsed.
  ///
  /// In en, this message translates to:
  /// **'Used it'**
  String get subscriptionMarkUsed;

  /// No description provided for @subscriptionUsageMarked.
  ///
  /// In en, this message translates to:
  /// **'Usage recorded'**
  String get subscriptionUsageMarked;

  /// No description provided for @subscriptionEditPrice.
  ///
  /// In en, this message translates to:
  /// **'Change price'**
  String get subscriptionEditPrice;

  /// No description provided for @subscriptionTrialUntil.
  ///
  /// In en, this message translates to:
  /// **'Trial until'**
  String get subscriptionTrialUntil;

  /// No description provided for @notificationScheduleSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} planned, days: {days}'**
  String notificationScheduleSummary(Object count, Object days);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
