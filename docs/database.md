# Реализация базы данных

Документ описывает текущий слой локальной базы данных приложения SubsFlow.
Фокус этого этапа: подключение SQLite, базовая схема, модели, DAO и репозитории.

## Используемые зависимости

В `pubspec.yaml` добавлены:

```yaml
path: 1.9.1
sqflite: 2.4.1
```

`sqflite` используется как локальная SQLite-база для iOS, Android и macOS.
`path` нужен для корректной сборки пути к файлу базы данных.

## Расположение кода

```text
lib/
├── data/
│   ├── local/
│   │   ├── app_database.dart
│   │   ├── subscription_dao.dart
│   │   ├── wallet_dao.dart
│   │   ├── transaction_dao.dart
│   │   ├── merchant_subscription_dao.dart
│   │   └── settings_dao.dart
│   ├── models/
│   │   ├── subscription_model.dart
│   │   ├── wallet_model.dart
│   │   ├── transaction_model.dart
│   │   ├── merchant_subscription_model.dart
│   │   └── settings_model.dart
│   └── repositories/
│       ├── subscription_repository_impl.dart
│       ├── wallet_repository_impl.dart
│       ├── transaction_repository_impl.dart
│       ├── merchant_subscription_repository_impl.dart
│       └── settings_repository_impl.dart
└── domain/
    └── repositories/
        ├── subscription_repository.dart
        ├── wallet_repository.dart
        ├── transaction_repository.dart
        ├── merchant_subscription_repository.dart
        └── settings_repository.dart
```

## Подключение к базе

Главная точка входа находится в `lib/data/local/app_database.dart`.

Класс `AppDatabase`:

- открывает файл базы `subsflow.db`;
- включает foreign keys через `PRAGMA foreign_keys = ON`;
- создаёт таблицы при первом запуске;
- создаёт индексы для частых запросов;
- добавляет дефолтный кошелёк и настройки;
- умеет полностью очищать пользовательские данные;
- умеет генерировать демо-данные после входа.

База реализована как singleton:

```dart
final db = await AppDatabase.instance.database;
```

## Таблицы

### subscriptions

Хранит пользовательские подписки.

Основные поля:

- `id` - идентификатор;
- `title` - название подписки;
- `category` - категория;
- `amount_cents` - сумма в копейках;
- `currency` - валюта, по умолчанию `RUB`;
- `billing_period` - период списания: например `weekly`, `monthly`, `yearly`;
- `next_payment_date` - дата следующего списания;
- `status` - статус, например `active` или `archived`;
- `icon_color` - цвет иконки;
- `description` - описание;
- `created_at`, `updated_at` - служебные даты.

Индексы:

- `idx_subscriptions_status`;
- `idx_subscriptions_next_payment`.

### wallets

Хранит состояние личного кошелька.

Используется одна запись с `id = 1`.

Поля:

- `balance_cents` - баланс в копейках;
- `auto_top_up_enabled` - включено ли автопополнение;
- `auto_top_up_threshold_cents` - порог автопополнения;
- `auto_top_up_amount_cents` - сумма автопополнения;
- `created_at`, `updated_at`.

### transactions

Хранит историю операций.

Поля:

- `id` - идентификатор;
- `subscription_id` - связанная подписка, если операция относится к подписке;
- `type` - тип операции, например `charge` или `top_up`;
- `amount_cents` - сумма;
- `currency` - валюта;
- `occurred_at` - дата операции;
- `note` - заметка.

При удалении подписки поле `subscription_id` становится `NULL`, а сама история не удаляется.

Индекс:

- `idx_transactions_occurred_at`.

### merchant_subscriptions

Хранит подписки, созданные пользователем как мерчантом.

Поля:

- `title` - название;
- `description` - описание;
- `price_cents` - цена;
- `currency` - валюта;
- `billing_period` - период;
- `subscribers_count` - количество подписчиков;
- `earned_cents` - заработано;
- `created_at`, `updated_at`.

### settings

Хранит настройки приложения и состояние входа.

Используется одна запись с `id = 1`.

Поля:

- `phone` - номер телефона пользователя;
- `notifications_enabled` - общий переключатель уведомлений;
- `notify_7_days`, `notify_3_days`, `notify_1_day` - сроки напоминаний;
- `face_id_enabled` - заглушка под Face ID;
- `timezone` - часовой пояс;
- `onboarding_completed` - завершён ли onboarding;
- `created_at`, `updated_at`.

## DAO-слой

DAO-классы напрямую работают с SQLite.

### SubscriptionDao

Файл: `lib/data/local/subscription_dao.dart`.

Реализовано:

- создание подписки;
- получение подписки по `id`;
- получение списка подписок;
- фильтрация по статусу;
- поиск по названию;
- получение ближайших списаний;
- обновление;
- архивирование;
- восстановление;
- удаление;
- отметка подписки как оплаченной.

Операция `markAsPaid` выполняется в транзакции:

1. Находит подписку.
2. Списывает сумму подписки с кошелька.
3. Создаёт запись в `transactions` с типом `charge`.
4. Переносит `next_payment_date` на следующий период.

### WalletDao

Файл: `lib/data/local/wallet_dao.dart`.

Реализовано:

- получение кошелька;
- пополнение баланса;
- настройка автопополнения;
- автопополнение при старте приложения, если баланс ниже порога.

### TransactionDao

Файл: `lib/data/local/transaction_dao.dart`.

Реализовано:

- создание транзакции;
- получение последних операций;
- получение операций за период;
- подсчёт общей суммы списаний за период.

### MerchantSubscriptionDao

Файл: `lib/data/local/merchant_subscription_dao.dart`.

Реализовано:

- создание мерчант-подписки;
- получение списка;
- обновление;
- удаление;
- вывод заработанных средств.

Минимальная сумма вывода сейчас зафиксирована как `10000` копеек, то есть 100 рублей.

### SettingsDao

Файл: `lib/data/local/settings_dao.dart`.

Реализовано:

- получение настроек;
- обновление состояния авторизации;
- обновление настроек уведомлений;
- обновление Face ID и часового пояса.

## Модели

Модели находятся в `lib/data/models`.

Каждая модель содержит:

- поля, соответствующие таблице;
- `toMap()` для записи в SQLite;
- `fromMap()` для чтения из SQLite.

Для дат используется ISO-строка через:

```dart
dateTime.toIso8601String()
DateTime.parse(value)
```

Деньги хранятся в копейках как `int`.
Это защищает от ошибок округления при работе с `double`.

## Репозитории

Контракты находятся в `lib/domain/repositories`.
Реализации находятся в `lib/data/repositories`.

Назначение репозиториев:

- скрыть SQLite от presentation-слоя;
- дать стабильный API для будущих usecase-классов и провайдеров;
- упростить замену источника данных в будущем.

Пример:

```dart
final repository = SubscriptionRepositoryImpl(
  SubscriptionDao(AppDatabase.instance),
);

final upcoming = await repository.getUpcoming();
```

## Демо-данные

Метод `seedDemoData` в `AppDatabase` создаёт:

- несколько активных подписок;
- кошелёк с балансом;
- настройки пользователя;
- одну мерчант-подписку.

Этот метод планируется использовать после успешного входа по демо-коду `123456`.

## Очистка данных

Метод `clearAllData` удаляет:

- транзакции;
- подписки;
- мерчант-подписки;
- кошелёк;
- настройки.

После очистки заново создаются дефолтные `wallets` и `settings`.

Это нужно для сценария выхода из аккаунта.

## Проверки

После реализации были выполнены:

```bash
dart format lib
flutter analyze
flutter test
```

Результат:

- форматирование прошло;
- статический анализ без ошибок;
- тесты прошли успешно.

## Следующие шаги

Рекомендуемый следующий этап:

1. Подключить репозитории к state management.
2. Добавить usecase-классы для ключевых сценариев.
3. Подключить генерацию демо-данных после авторизации.
4. Заменить временный Flutter counter screen на реальные экраны приложения.
5. Добавить тесты для `markAsPaid`, автопополнения и расчётов истории.
