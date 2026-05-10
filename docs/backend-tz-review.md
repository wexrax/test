# Backend review по ТЗ

Дата ревью: 2026-05-07

Документ фиксирует состояние backend/data части приложения относительно `docs/converted-document.md`.

## Что уже реализовано

- Локальная SQLite база `subsflow.db` через `sqflite`.
- Слой `data/local` с DAO для подписок, кошелька, транзакций, merchant-подписок и настроек.
- Слой `data/repositories` и контракты в `domain/repositories`.
- Riverpod-провайдеры репозиториев в `lib/presentation/providers/repository_providers.dart`.
- Демо-авторизация: после успешного входа создаются demo-data, телефон сохраняется в `settings`.
- Logout очищает локальную БД через `AppDatabase.clearAllData()`.
- Подписки сохраняются локально, поддерживают active/archive, поиск, ближайшие списания.
- Функция "Я уже оплатил" списывает деньги с кошелька, создает transaction и сдвигает дату следующего списания.
- Просроченная подписка при оплате сдвигается до будущей даты, а не только на один период.
- Кошелек хранит баланс, настройки автопополнения и историю операций.
- Автопополнение выполняется при старте приложения, если баланс ниже порога.
- История операций загружается по выбранному периоду через repository/DAO, без ограничения последними 50 транзакциями.
- Merchant-подписки сохраняются локально, поддерживают создание, список и вывод earned от 100 рублей.
- `created_at` у merchant-подписок не перезаписывается при update.
- Настройки уведомлений, Face ID-заглушка, timezone и onboarding/login state сохраняются в SQLite.
- CSV export формируется по всем подпискам, включая статус.
- Local notifications для напоминаний за 7/3/1 день реализованы через `flutter_local_notifications` и `timezone`.
- `NotificationService` централизует offline-уведомления: состояние permission `unknown / granted / denied / unsupported`, запрос разрешений, тестовое уведомление и отмену управляемых уведомлений.
- Scheduler пересобирает pending reminders при изменении подписок, timezone и переключателей 7/3/1; в расписание попадают только `active` подписки без `archive_at`.
- Экран настроек показывает статус разрешений, краткую сводку расписания, кнопку запроса permission, тестовое уведомление и ручное обновление расписания.
- Tap по payload `subscription:<id>` и `archive:<id>` ведет на detail подписки, а если записи уже нет - на `/subscriptions`.
- Archive timer реализован через `archive_at`, local notification и Android alarm.
- Система архива разделяет derived-состояния подписки: `active`, `pendingArchive` и `archived`.
- `pendingArchive` означает `status = active` и `archive_at != null`: подписка сразу скрывается из активных поверхностей, но отображается во вкладке архива до фактического срабатывания таймера.
- Active-поверхности используют только подписки без `archive_at`: дашборд, ближайшие списания, календарь, расходы, категории, active tab и reminder scheduling.
- Схема БД поднята до версии 3 и валидирует доменные значения через `CHECK`.
- Есть миграция v2 -> v3 с перестройкой таблиц и нормализацией legacy-значений.
- Добавлены backend-тесты на оплату просрочки, автопополнение, merchant update, CSV, историю больше 50 операций, constraints и миграцию.

## Что осталось по backend части

### 1. Domain/usecase слой

В ТЗ отдельно указаны `domain/entities` и `domain/usecases`.

Сейчас есть repository contracts, но:

- `domain/entities` отсутствуют;
- `domain/usecases` отсутствуют;
- часть бизнес-логики живет в DAO и Riverpod notifier-ах.

Рекомендуемый следующий шаг:

- вынести use cases: `MarkSubscriptionAsPaid`, `GetHistoryByPeriod`, `ApplyStartupAutoTopUp`, `ExportSubscriptionsCsv`, `WithdrawMerchantEarnings`;
- постепенно развести data models и domain entities, если проект будет расти.

### 2. Уведомления: приемочная проверка на устройствах

Backend-код планирования и permission flow есть, но по ТЗ надо подтвердить фактическое поведение на устройствах:

- Android: выдать permission, нажать "Тестовое уведомление", увидеть notification и проверить переход по tap;
- Android: проверить scheduled reminders после ручной смены даты/времени или через тестовую близкую дату;
- Android: проверить, что pending archive подписки не создают payment reminders, но archive timer notification остается;
- iOS: проверить permissions, test notification и scheduled local notifications на iOS-сборке;
- уточнить, достаточно ли offline local notifications. Если нужны именно серверные push, потребуется отдельный backend/FCM/APNs/device tokens.

### 3. Platform/build acceptance

Для backend/data части важно отдельно подтвердить:

- `flutter build apk`;
- iOS build на macOS;
- что `sqflite`, notifications и alarm manager корректно работают на целевых версиях Android/iOS из ТЗ.

### 4. Import CSV / banking statement

Это бонус-функция из ТЗ, пока не реализована.

Нужно добавить:

- парсер CSV;
- валидацию входных строк;
- маппинг колонок в `SubscriptionModel`;
- обработку дублей;
- тесты на импорт.

### 5. Home screen widget

Бонус-функция из ТЗ, пока не реализована.

Для backend/data части потребуется:

- подготовить компактный read model для ближайших списаний;
- синхронизация данных виджета с локальной БД;
- platform-specific код для Android/iOS widget.

## Что стоит улучшить дополнительно

- Добавить enum/value objects для `billingPeriod`, `subscriptionStatus`, `transactionType`, чтобы не передавать raw strings между слоями.
- Добавить repository/usecase tests для настроек уведомлений и logout/clear DB.
- Перевести hardcoded строки ошибок и служебные тексты в `.arb`.
- Добавить миграционные тесты для будущих версий схемы при каждом изменении БД.

## Текущие проверки

Актуальные проверки после backend-правок:

```bash
flutter analyze
flutter test
```

Результат:

- `flutter analyze` проходит без issues;
- `flutter test` проходит, 17 тестов.
