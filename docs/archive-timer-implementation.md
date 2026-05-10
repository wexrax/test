# Таймер автоархивации подписок

## Что реализовано

- SQLite-схема поднята до версии `2`.
- В таблицу `subscriptions` добавлена nullable-колонка `archive_at TEXT` и индекс `idx_subscriptions_archive_at`.
- В `SubscriptionModel`, `SubscriptionData`, DAO и repository добавлено поле `archiveAt`.
- Добавлены backend-методы `scheduleArchive`, `clearArchiveTimer` и `archiveDueSubscriptions`.
- `archive`, `restore` и `delete` очищают/отменяют таймер, чтобы автоархивация не срабатывала повторно.
- При старте приложения, загрузке подписок и возврате приложения в foreground запускается reconciliation: все активные подписки с `archiveAt <= now` переносятся в архив.

## Scheduling

- Android использует `android_alarm_manager_plus`: для каждой подписки создается alarm на выбранную дату в `09:00`.
- Alarm callback открывает локальную SQLite-базу и вызывает `archiveDueSubscriptions(DateTime.now())`.
- Если exact alarm недоступен, код переключается на inexact fallback; reconciliation при запуске/возврате остается обязательной защитой.
- iOS/macOS используют local notification, а фактическая запись в SQLite догоняется при запуске или возврате приложения.

## UI

- В деталях активной подписки добавлена кнопка `Таймер архива`.
- Пользователь выбирает дату через `showDatePicker`.
- Выбранная дата сохраняется как `09:00` выбранного дня.
- Если таймер задан, в деталях показывается дата автоархивации и доступна кнопка сброса.
- Архивные подписки не показывают настройку таймера как активное действие.

## Проверка

- `flutter pub get` скачал `android_alarm_manager_plus`, но Windows остановил создание plugin-symlink из-за выключенного Developer Mode.
- После включения Developer Mode нужно повторить `flutter pub get`, затем прогнать `flutter analyze`, `flutter test` и Android debug build.
