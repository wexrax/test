// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Мои Подписки';

  @override
  String get onboardingSkip => 'Пропустить';

  @override
  String get onboardingNext => 'Далее';

  @override
  String get onboardingStart => 'Начать';

  @override
  String get phoneTitle => 'Введите номер телефона';

  @override
  String get phoneHint => '+7 (999) 999-99-99';

  @override
  String get agreeToTerms => 'Я согласен с условиями оферты';

  @override
  String get codeTitle => 'Введите код из SMS';

  @override
  String get demoCode => '123456';

  @override
  String get loginButton => 'Войти';

  @override
  String get logoutButton => 'Выйти';

  @override
  String get greeting => 'Добрый день 👋';

  @override
  String get yourBudget => 'Ваш бюджет';

  @override
  String get dashboardTitle => 'Дашборд';

  @override
  String get monthlySpending => 'Траты в месяц';

  @override
  String subscriptionCount(Object count) {
    return 'Подписок: $count';
  }

  @override
  String yearlySpending(Object amount) {
    return 'В год: $amount';
  }

  @override
  String averageCheck(Object amount) {
    return 'Средний чек: $amount';
  }

  @override
  String nextPayment(Object date) {
    return 'Следующее списание: $date';
  }

  @override
  String walletBalance(Object amount) {
    return 'Баланс: $amount';
  }

  @override
  String walletSufficientFor(Object months) {
    return 'Хватит на $months мес.';
  }

  @override
  String get vsMarket => 'vs рынок (2500 ₽)';

  @override
  String get quickActions => 'Быстрые действия';

  @override
  String get addSubscription => 'Добавить';

  @override
  String get addSubscriptionTitle => 'Добавить подписку';

  @override
  String get customSubscriptionTitle => 'Своя подписка';

  @override
  String get customSubscriptionSubtitle =>
      'Добавьте сервис с любой ценой и периодом';

  @override
  String get customSubscriptionNameHint => 'Например, Telegram Premium';

  @override
  String get customSubscriptionCategoryHint => 'Например, Связь';

  @override
  String get customSubscriptionNameRequired => 'Введите название подписки';

  @override
  String get customSubscriptionCategoryRequired => 'Введите категорию';

  @override
  String get customSubscriptionPriceRequired => 'Введите стоимость';

  @override
  String get customSubscriptionPriceInvalid => 'Введите сумму больше 0';

  @override
  String get periodWeekly => 'В неделю';

  @override
  String get firstPaymentDate => 'Первое списание';

  @override
  String get trialPeriod => 'Пробный период';

  @override
  String get trialEnd => 'Окончание триала';

  @override
  String get cancelAfterTrial => 'Отменить после триала';

  @override
  String subscriptionAdded(Object name) {
    return 'Подписка «$name» добавлена';
  }

  @override
  String get calendar => 'Календарь';

  @override
  String get history => 'История';

  @override
  String get export => 'Экспорт';

  @override
  String get upcomingPayments => 'Ближайшие списания';

  @override
  String get categories => 'По категориям';

  @override
  String get activeSubscriptions => 'Активные';

  @override
  String get archivedSubscriptions => 'Архив';

  @override
  String get searchHint => 'Поиск по названию';

  @override
  String get detailTitle => 'Подписка';

  @override
  String get category => 'Категория';

  @override
  String get period => 'Период';

  @override
  String get status => 'Статус';

  @override
  String get yearlyAmount => 'Годовая сумма';

  @override
  String get markAsPaid => 'Я уже оплатил';

  @override
  String get edit => 'Редактировать';

  @override
  String get cancelDelete => 'Отменить / Удалить';

  @override
  String get cancelSubscription => 'Отменить';

  @override
  String get restoreSubscription => 'Восстановить';

  @override
  String get deleteSubscription => 'Удалить';

  @override
  String get cancelSubscriptionTitle => 'Отменить подписку?';

  @override
  String get cancelSubscriptionMessage => 'Подписка уйдет в архив.';

  @override
  String get deleteSubscriptionTitle => 'Удалить подписку?';

  @override
  String get deleteSubscriptionMessage => 'Подписка будет удалена навсегда.';

  @override
  String get calendarTitle => 'Календарь списаний';

  @override
  String get today => 'Сегодня';

  @override
  String get tomorrow => 'Завтра';

  @override
  String inDays(Object days) {
    return 'Через $days дн.';
  }

  @override
  String get walletTitle => 'Кошелёк';

  @override
  String get topUp => 'Пополнить';

  @override
  String get autoTopUp => 'Авто';

  @override
  String get autoTopUpSettings => 'Настройки автопополнения';

  @override
  String get threshold => 'Порог';

  @override
  String get amount => 'Сумма';

  @override
  String get transactionHistory => 'Последние операции';

  @override
  String get topUpModalTitle => 'Пополнение кошелька';

  @override
  String get enterAmount => 'Введите сумму';

  @override
  String get cancel => 'Отмена';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get historyTitle => 'История списаний';

  @override
  String get filterPeriod => 'Период';

  @override
  String get month => 'Месяц';

  @override
  String get quarter => 'Квартал';

  @override
  String get year => 'Год';

  @override
  String totalForPeriod(Object amount) {
    return 'Итого за период: $amount';
  }

  @override
  String get merchantTitle => 'Свои подписки';

  @override
  String get createMerchant => 'Создать подписку';

  @override
  String get name => 'Название';

  @override
  String get description => 'Описание';

  @override
  String get price => 'Цена';

  @override
  String get periodMonthly => 'В месяц';

  @override
  String get periodYearly => 'В год';

  @override
  String get link => 'Ссылка';

  @override
  String get withdraw => 'Вывод';

  @override
  String get minWithdraw => 'Минимальная сумма 100 ₽';

  @override
  String subscribersCount(Object count) {
    return 'Подписчиков: $count';
  }

  @override
  String earned(Object amount) {
    return 'Заработано: $amount';
  }

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileAccountEyebrow => 'Ваш аккаунт';

  @override
  String get profilePremiumEyebrow => 'Финансовый профиль';

  @override
  String get profileDefaultName => 'Добрый пользователь';

  @override
  String get profileSectionsTitle => 'Разделы';

  @override
  String get profileActionsTitle => 'Центр управления';

  @override
  String get profileActiveStat => 'активные';

  @override
  String get profileMonthlyPlanStat => 'план/мес.';

  @override
  String get profileWalletStat => 'кошелёк';

  @override
  String get profileExportTitle => 'Экспорт';

  @override
  String get profileMerchantSubtitle => 'Создавайте и продавайте';

  @override
  String get profileWalletSubtitle => 'Баланс и автопополнение';

  @override
  String get profileHistorySubtitle => 'Все списания';

  @override
  String get profileExportSubtitle => 'Скачать CSV';

  @override
  String get profileSettingsSubtitle => 'Уведомления и безопасность';

  @override
  String get phone => 'Телефон';

  @override
  String get settings => 'Настройки';

  @override
  String get notifications => 'Уведомления';

  @override
  String get notify7days => 'За 7 дней';

  @override
  String get notify3days => 'За 3 дня';

  @override
  String get notify1day => 'За 1 день';

  @override
  String get faceID => 'Face ID / Touch ID';

  @override
  String get timezone => 'Часовой пояс';

  @override
  String get exportCsv => 'Экспортировать CSV';

  @override
  String get dataExported => 'Данные экспортированы';

  @override
  String get done => 'Готово';

  @override
  String get paidSuccess => 'Оплата учтена';

  @override
  String get insufficientFunds => 'Недостаточно средств';
  @override
  String get archiveTimer => 'Таймер архива';

  @override
  String archiveScheduledAt(Object date) {
    return 'Архивируется: $date';
  }

  @override
  String get clearArchiveTimer => 'Сбросить таймер';

  @override
  String get archiveTimerSaved => 'Таймер архива сохранён';

  @override
  String get archiveTimerCleared => 'Таймер архива сброшен';

  @override
  String get notificationPermissionStatus => 'Статус уведомлений';

  @override
  String get notificationPermissionGranted => 'Разрешены';

  @override
  String get notificationPermissionDenied => 'Запрещены';

  @override
  String get notificationPermissionUnknown => 'Еще не запрошены';

  @override
  String get notificationPermissionUnsupported =>
      'Не поддерживаются на этом устройстве';

  @override
  String get requestNotificationsPermission => 'Разрешить уведомления';

  @override
  String get testNotification => 'Тестовое уведомление';

  @override
  String get testNotificationSent => 'Тестовое уведомление отправлено';

  @override
  String get refreshNotificationSchedule => 'Обновить расписание';

  @override
  String get notificationScheduleRefreshed =>
      'Расписание уведомлений обновлено';

  @override
  String get analyticsTotalMonth => 'Всего за месяц';

  @override
  String get analyticsSpendingDynamics => 'Динамика трат';

  @override
  String get analyticsTrials => 'Пробные периоды';

  @override
  String get analyticsInactiveSubscriptions => 'Неиспользуемые подписки';

  @override
  String get analyticsPriceHistoryTitle => 'История изменения цен';

  @override
  String get subscriptionMarkUsed => 'Использовал';

  @override
  String get subscriptionUsageMarked => 'Использование отмечено';

  @override
  String get subscriptionEditPrice => 'Изменить цену';

  @override
  String get subscriptionTrialUntil => 'Триал до';

  @override
  String notificationScheduleSummary(Object count, Object days) {
    return 'Запланировано: $count, дни: $days';
  }
}
