// lib/l10n/app_localizations.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ru'),
  ];

  String get appTitle;
  String get onboardingSkip;
  String get onboardingNext;
  String get onboardingStart;
  String get phoneTitle;
  String get phoneHint;
  String get agreeToTerms;
  String get codeTitle;
  String get demoCode;
  String get loginButton;
  String get logoutButton;
  String get dashboardTitle;
  String get monthlySpending;
  String subscriptionCount(Object count);
  String yearlySpending(Object amount);
  String averageCheck(Object amount);
  String nextPayment(Object date);
  String walletBalance(Object amount);
  String walletSufficientFor(Object months);
  String get vsMarket;
  String get quickActions;
  String get addSubscription;
  String get calendar;
  String get history;
  String get export;
  String get upcomingPayments;
  String get categories;
  String get activeSubscriptions;
  String get archivedSubscriptions;
  String get searchHint;
  String get detailTitle;
  String get category;
  String get period;
  String get status;
  String get yearlyAmount;
  String get markAsPaid;
  String get edit;
  String get cancelDelete;
  String get calendarTitle;
  String get today;
  String get tomorrow;
  String inDays(Object days);
  String get walletTitle;
  String get topUp;
  String get autoTopUp;
  String get autoTopUpSettings;
  String get threshold;
  String get amount;
  String get transactionHistory;
  String get topUpModalTitle;
  String get enterAmount;
  String get cancel;
  String get confirm;
  String get historyTitle;
  String get filterPeriod;
  String get month;
  String get quarter;
  String get year;
  String totalForPeriod(Object amount);
  String get merchantTitle;
  String get createMerchant;
  String get name;
  String get description;
  String get price;
  String get periodMonthly;
  String get periodYearly;
  String get link;
  String get withdraw;
  String get minWithdraw;
  String subscribersCount(Object count);
  String earned(Object amount);
  String get profileTitle;
  String get phone;
  String get settings;
  String get notifications;
  String get notify7days;
  String get notify3days;
  String get notify1day;
  String get faceID;
  String get timezone;
  String get exportCsv;
  String get dataExported;
  String get done;
  String get paidSuccess;
  String get insufficientFunds;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
        lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'ru':
      return AppLocalizationsRu();
    case 'en':
      return AppLocalizationsEn();
    default:
      return AppLocalizationsRu();
  }
}