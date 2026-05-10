# SubsFlow / Мои Подписки

Flutter-приложение для учета подписок, кошелька и списаний. Проект сейчас работает как frontend-only прототип с локальной SQLite-базой: данные авторизации, подписок, кошелька, транзакций, мерчант-подписок и настроек сохраняются на устройстве без внешнего backend.

## Что умеет приложение

- Онбординг и демо-авторизация по телефону.
- Дашборд с месячным/годовым планом подписок, кошельком, ближайшими списаниями и категориями.
- Список подписок с активными и архивными записями.
- Детальный экран подписки: отметить как оплаченную, архивировать, восстановить, удалить, настроить таймер автоархивации.
- Добавление подписки из встроенных шаблонов популярных сервисов.
- Календарь будущих списаний.
- Кошелек: баланс, пополнение, автопополнение и история операций.
- Аналитика: текущий месячный план, динамика трат, категории с трендом, триалы, неиспользуемые подписки, рекомендации экономии, ближайшие списания и бюджетный лимит.
- Мерчант-раздел: создание собственных подписок, статистика подписчиков и вывод заработка.
- Профиль с быстрыми действиями, CSV-экспортом и logout.
- Настройки уведомлений, часового пояса, Face ID-заглушки и личного месячного лимита.
- Локальные уведомления за 7/3/1 день до списаний и уведомления для таймера архивации.

## Технологии

- Flutter `>=3.22.0`, Dart `>=3.2.0 <4.0.0`.
- `flutter_riverpod` для состояния и dependency injection.
- `go_router` с `StatefulShellRoute` и нижней навигацией.
- `sqflite` + DAO/repository слой для локального хранения.
- `flutter_local_notifications`, `timezone`, `android_alarm_manager_plus` для локальных напоминаний и автоархивации.
- `csv`, `path_provider`, `share_plus` для CSV-экспорта.
- `google_fonts` и локальные theme/constants для UI.
- Локализация через ARB в `lib/l10n/`; основной locale в приложении сейчас `ru`.

## Структура проекта

```text
lib/
  main.dart                         # bootstrap, services, MaterialApp.router
  core/
    constants/                      # AppColors, AppDimens
    services/                       # notifications, archive timer
    themes/                         # light/dark theme
    utils/                          # currency/date/export helpers
    widgets/                        # reusable UI widgets
  data/
    local/                          # AppDatabase and SQLite DAO classes
    models/                         # DB-facing models
    repositories/                   # repository implementations
  domain/
    repositories/                   # repository contracts
  presentation/
    providers/                      # Riverpod state and derived providers
    router/                         # go_router setup and main shell nav
    screens/                        # app screens and flows
  l10n/                             # ARB and generated localization files
test/
  backend_data_test.dart            # data, analytics, reminders, DB migration tests
  widget_test.dart                  # smoke test
docs/                               # product, design, DB, backend notes
android/, ios/                      # platform configuration
```

## Архитектура

Код следует слоистой структуре:

- UI в `lib/presentation/screens` читает Riverpod-провайдеры и вызывает notifier-методы.
- `lib/presentation/providers` содержит состояние экранов, derived-провайдеры и связывает UI с domain contracts.
- `lib/domain/repositories` описывает контракты для подписок, кошелька, транзакций, мерчанта и настроек.
- `lib/data/repositories` реализует контракты через DAO.
- `lib/data/local` напрямую работает с SQLite.

Главный роутер находится в `lib/presentation/router/app_router.dart`. Основные разделы в нижней навигации:

- `/dashboard`
- `/subscriptions`
- `/analytics`
- `/wallet`
- `/profile`

Вне нижней навигации открываются `/calendar`, `/history`, `/merchants`, `/merchants/create`, `/settings`, `/add-subscription` и детали `/subscriptions/:id`.

## Локальная база данных

Точка входа: `lib/data/local/app_database.dart`.

- Файл базы: `subsflow.db`.
- Текущая версия схемы: `6`.
- Таблицы: `subscriptions`, `wallets`, `transactions`, `merchant_subscriptions`, `settings`.
- При открытии включаются foreign keys и создаются обязательные записи кошелька/настроек.
- При успешном входе `seedDemoData(phone: ...)` заменяет пользовательские данные демо-набором.
- При logout `clearAllData()` очищает пользовательские данные и пересоздает дефолты.
- Миграции добавляют `archive_at`, constraints, `monthly_budget_cents`, `hidden_savings_recommendations`, поля триалов/использования и таблицы истории использования/изменения цен.

Подробности: [docs/database.md](docs/database.md).

## Уведомления и таймер архивации

- `NotificationService` управляет local notifications, permission state, тестовым уведомлением и payload-навигацией.
- `subscriptionReminderSyncProvider` пересобирает расписание напоминаний при изменении настроек или активных подписок.
- `ArchiveTimerService` использует in-memory `Timer`, local notification и Android AlarmManager fallback.
- Reconciliation автоархивации запускается при старте приложения, после загрузки подписок и при возврате приложения в foreground.

Подробности: [docs/archive-timer-implementation.md](docs/archive-timer-implementation.md).

## Команды разработки

Запускать из корня репозитория.

```bash
flutter pub get
flutter run
flutter analyze
dart format lib test
flutter test
flutter build apk
```

На Windows при работе с Flutter-плагинами может потребоваться включенный Developer Mode, чтобы `flutter pub get` мог создавать plugin symlinks.

## Тесты

Основной набор находится в `test/backend_data_test.dart` и покрывает:

- оплату подписки и перенос даты следующего списания;
- автопополнение кошелька;
- сохранение настроек и бюджета;
- мерчант-обновления;
- таймер автоархивации;
- активные/архивные collections;
- аналитические расчеты;
- расписание уведомлений;
- CSV-экспорт;
- историю транзакций;
- DB constraints и миграцию legacy-схемы.

Перед PR или крупной правкой запускайте:

```bash
flutter analyze
flutter test
```

## Документация

- [docs/design-system.md](docs/design-system.md) - дизайн-система и UI-токены.
- [docs/database.md](docs/database.md) - SQLite-схема, DAO, модели и репозитории.
- [docs/analytics-tz-implementation.md](docs/analytics-tz-implementation.md) - реализация блока аналитики по ТЗ v2.
- [docs/backend-implementation.md](docs/backend-implementation.md) - история подключения локального backend-слоя.
- [docs/backend-tz-review.md](docs/backend-tz-review.md) - review backend-части по ТЗ.
- [docs/tz-remaining-checklist.md](docs/tz-remaining-checklist.md) - текущий checklist реализации.
- [docs/ТЗ_Блок_Аналитики_v2.md](docs/ТЗ_Блок_Аналитики_v2.md) - ТЗ аналитического дашборда.

## Важные ограничения

- Это локальный prototype/offline-first слой, не серверный backend.
- В проекте еще остаются hardcoded UI-строки рядом с ARB-локализацией; новые строки лучше добавлять в `app_ru.arb` и `app_en.arb`.
- Редактирование подписки на детальном экране пока помечено TODO.
- Фактический показ уведомлений нужно проверять на реальных Android/iOS устройствах отдельно от unit-тестов.
- Импорт CSV/банковских выписок и server push не реализованы.
