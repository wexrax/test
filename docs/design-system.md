# Дизайн-система «Мои Подписки»

> Документ основан на реальных скриншотах прототипа. Является единственным источником истины для дизайнеров и разработчиков Flutter-приложения.

---

## Содержание

1. [Принципы](#1-принципы)
2. [Цвета](#2-цвета)
3. [Типографика](#3-типографика)
4. [Отступы и сетка](#4-отступы-и-сетка)
5. [Иконки и аватары](#5-иконки-и-аватары)
6. [Компоненты](#6-компоненты)
7. [Экраны](#7-экраны)
8. [Анимации и переходы](#8-анимации-и-переходы)
9. [Тёмная тема](#9-тёмная-тема)
10. [Токены Flutter (Dart)](#10-токены-flutter-dart)

---

## 1. Принципы

| # | Принцип | Суть |
|---|---------|------|
| 1 | **Тепло** | Фон кремовый (`#EDEAE4`), а не холодный белый. Оранжевый акцент энергичный, но не тревожный. |
| 2 | **Контраст** | Тёмная карточка бюджета контрастирует со светлым фоном — главное число всегда читается первым. |
| 3 | **Плоскость** | Минимум теней. Разграничение достигается цветом фона и тонкими разделителями. |
| 4 | **Один акцент** | В приложении один акцентный цвет — оранжевый. Никаких вторых акцентов, никакого фиолетового. |

---

## 2. Цвета

### 2.1 Палитра бренда

| Токен | Hex | Применение |
|-------|-----|------------|
| `colorPrimary` | `#F2530A` | CTA-кнопки, FAB, активные иконки навбара, акценты |
| `colorPrimaryLight` | `#FFF0EA` | Фон чипов, hover-состояния, ripple |
| `colorPrimaryDark` | `#C43D00` | Pressed-state кнопок |

### 2.2 Нейтральная палитра

| Токен | Hex | Применение |
|-------|-----|------------|
| `colorBackground` | `#EDEAE4` | Фон всех экранов (тёплый кремовый) |
| `colorSurface` | `#FFFFFF` | Карточки, Bottom Sheet, поля ввода |
| `colorSurfaceVariant` | `#F5F3EF` | Поисковое поле, вторичные поверхности |
| `colorDivider` | `#E8E4DC` | Разделители в списках, рамки полей |
| `colorTextPrimary` | `#1A1A1A` | Заголовки, основной текст, суммы |
| `colorTextSecondary` | `#8A8580` | Подписи, метки, даты, хинты |
| `colorTextDisabled` | `#C4C0BA` | Неактивные элементы |
| `colorTextOnPrimary` | `#FFFFFF` | Текст поверх оранжевого и тёмной карточки |

### 2.3 Специальные поверхности

| Токен | Значение | Применение |
|-------|----------|------------|
| `colorBudgetCardBg` | `gradient: #1A0A00 → #2D1500 → #1A0A00` | Главная карточка «Траты в месяц» |
| `colorBudgetCardSecondary` | `rgba(255,255,255,0.55)` | Вторичные лейблы внутри тёмной карточки |
| `colorWalletCardBg` | `gradient: #F2530A → #E04500` | Карточка кошелька (оранжевая) |

### 2.4 Семантические цвета

| Токен | Hex | Применение |
|-------|-----|------------|
| `colorSuccess` | `#22C55E` | Пополнение кошелька (+), положительные изменения |
| `colorError` | `#EF4444` | Ошибки, «через 1д» (критический срок) |

> **Срок списания → цвет «через Nd»:** 1–2 дня → `colorError`, 3–7 дней → `colorPrimary`, 8+ дней → `colorTextSecondary`.

### 2.5 Цвета аватаров

Каждая первая буква названия сервиса получает уникальный цвет через алгоритм хэша:

| Пример | Цвет фона | Цвет текста |
|--------|-----------|-------------|
| N (Netflix) | `#E50914` | белый |
| S (Spotify) | `#1DB954` | белый |
| Я (Яндекс) | `#FFDD2D` | `#1A1A1A` (тёмный!) |
| G (GitHub) | `#1A1A1A` | белый |
| I (iCloud) | `#147EFB` | белый |
| M (МТС) | `#E50914` | белый |

Если цвет фона аватара светлый (яркость > 0.6) — текст тёмный, иначе белый.

### 2.6 Правила

- `colorPrimary` только на интерактивных элементах. Никогда для декоративных целей.
- Тёмная карточка бюджета — всегда с градиентом, никогда не плоская.
- На кремовом фоне `colorBackground` белые карточки выделяются без теней.
- Деструктивные действия — текстовая кнопка `colorError`, без заливки.

---

## 3. Типографика

### 3.1 Шрифт

**Основной и единственный шрифт:** `Inter`

```yaml
# pubspec.yaml
fonts:
  - family: Inter
    fonts:
      - asset: assets/fonts/Inter-Regular.ttf
        weight: 400
      - asset: assets/fonts/Inter-Medium.ttf
        weight: 500
      - asset: assets/fonts/Inter-SemiBold.ttf
        weight: 600
      - asset: assets/fonts/Inter-Bold.ttf
        weight: 700
      - asset: assets/fonts/Inter-ExtraBold.ttf
        weight: 800
```

### 3.2 Шкала стилей

| Токен | Size | Weight | Применение |
|-------|------|--------|------------|
| `displayLarge` | 28 sp | 800 | Заголовок онбординга |
| `displayMedium` | 24 sp | 700 | Заголовки auth-экранов («Вход без пароля») |
| `headlineLarge` | 20 sp | 700 | Заголовок экрана в AppBar («Ваш бюджет», «Профиль») |
| `headlineMedium` | 32 sp | 700 | Сумма в Budget Card — крупно, моноширинно |
| `headlineSmall` | 16 sp | 600 | Заголовок секции, Bottom Sheet |
| `titleLarge` | 15 sp | 600 | Название подписки в списке |
| `bodyLarge` | 15 sp | 400 | Основной текст, описания |
| `bodyMedium` | 13 sp | 400 | Вторичный текст, подписи под названием |
| `bodySmall` | 11 sp | 400 | Даты, хинты, кэпшн AppBar |
| `labelLarge` | 15 sp | 600 | Текст кнопки (Далее, Войти, Сохранить) |
| `labelMedium` | 11 sp | 500 | Метка таба навбара |
| `overline` | 10 sp | 500 | «ТРАТЫ В МЕСЯЦ», «ДОСТУПНО» — UPPERCASE, letterSpacing 1.2 |

### 3.3 Особые правила

- Числовые суммы → `fontFeatures: [FontFeature.tabularFigures()]`.
- Лейблы в карточках («ТРАТЫ В МЕСЯЦ») → `overline`, `toUpperCase()`.
- AppBar всегда имеет двойной заголовок: кэпшн (`bodySmall`, `colorTextSecondary`) + заголовок (`headlineLarge`).

---

## 4. Отступы и сетка

### 4.1 Базовая единица — 4 dp

| Токен | Значение | Применение |
|-------|----------|------------|
| `s4` | 4 dp | Иконка–текст, минимальный gap |
| `s8` | 8 dp | Между элементами, gap карточек в строке |
| `s12` | 12 dp | Паддинг маленьких элементов |
| `s16` | 16 dp | Горизонтальный паддинг экрана, паддинг карточки |
| `s20` | 20 dp | Внутренний паддинг крупных карточек |
| `s24` | 24 dp | Отступ между секциями дашборда |
| `s32` | 32 dp | Расстояние между крупными блоками |

### 4.2 Горизонтальный паддинг экрана

```
|← 16dp →|  [Контент]  |← 16dp →|
```

Budget Card и Wallet Card — на полную ширину без внешнего паддинга, содержимое внутри с паддингом 20 dp.

### 4.3 Скругления

| Токен | Значение | Применение |
|-------|----------|------------|
| `radiusXS` | 4 dp | Чипы «через Nd» |
| `radiusS` | 8 dp | Поля ввода, кнопки внутри карточек |
| `radiusM` | 12 dp | Аватары подписок (rounded square) |
| `radiusL` | 16 dp | Карточки дашборда, Quick Action кнопки |
| `radiusXL` | 20 dp | Bottom Sheet (верхние углы), диалоги |
| `radiusFull` | 999 dp | Pill Toggle, FAB, аватар профиля, Search Field |

### 4.4 Стандартные высоты

| Элемент | Высота |
|---------|--------|
| Primary Button | 52 dp |
| Text Field | 52 dp |
| Search Field | 44 dp |
| Pill Toggle | 40 dp |
| List Item (подписка) | 68 dp |
| Quick Action Button | 64 dp |
| Bottom Nav Bar | 82 dp (с safe area) |
| FAB диаметр | 52 dp |

---

## 5. Иконки и аватары

### 5.1 Иконпак

**Пакет:** `lucide_icons` (pub.dev)  
**Размер:** 22 dp (навбар — 22 dp, действия — 20 dp)

| Место / Действие | Иконка Lucide |
|-----------------|---------------|
| Главная (навбар) | `home` |
| Подписки | `grid-2x2` |
| Кошелёк | `wallet` |
| Профиль | `user` |
| FAB | `plus` |
| Добавить (дашборд) | `circle-plus` |
| Календарь | `calendar-days` |
| История | `clock` |
| Экспорт | `download` |
| Уведомления | `bell` |
| Настройки | `settings` |
| Поиск | `search` |
| Назад | `arrow-left` |
| Закрыть | `x` |
| Редактировать | `pen-line` |
| Удалить | `trash-2` |
| Автопополнение | `refresh-cw` |
| Выйти | `log-out` |
| Транзакция (пополнение) | `arrow-down-to-line` |
| Транзакция (списание) | `arrow-up-from-line` |

### 5.2 Аватары подписок

**Форма:** Rounded square — `BorderRadius.circular(12)` (radiusM)

| Контекст | Размер |
|----------|--------|
| Список подписок | 40 × 40 dp |
| Ближайшие списания (дашборд) | 36 × 36 dp |
| Детальный экран | 72 × 72 dp |

Текст — первая заглавная буква названия, `FontWeight.w700`, `fontSize: 16–18` в зависимости от размера.

### 5.3 Аватар профиля

Круглый, диаметр 60 dp, фон `colorPrimary` (оранжевый), инициал белый.

---

## 6. Компоненты

### 6.1 Кнопки

#### Primary Button

```
╔══════════════════════════════════════╗
║         Далее  →                     ║
╚══════════════════════════════════════╝
height: 52dp | radius: radiusM (12dp)
bg: colorPrimary | text: labelLarge, белый
Pressed: bg colorPrimaryDark, scale 0.98
Disabled: bg colorTextDisabled opacity 0.6
Иконка «→» на auth-кнопках: Arrow right, 16dp, белая
```

#### Ghost Button (Пропустить, Отмена)

```
Пропустить
height: 44dp | нет фона, нет рамки
text: labelLarge, colorTextPrimary
Pressed: opacity 0.5
```

#### Кнопки внутри Wallet Card

```
╔══════════════╗  ╔══════════════╗
║  + Пополнить ║  ║  ↺ Авто      ║
╚══════════════╝  ╚══════════════╝
height: 38dp | radius: radiusS
bg: rgba(255,255,255,0.20)
border: 1dp rgba(255,255,255,0.35)
text: labelMedium, белый
```

### 6.2 Поля ввода

#### Text Field

```
┌──────────────────────────────────┐
│  Floating label                  │  titleMedium, colorTextSecondary
│  Текст                           │  bodyLarge, colorTextPrimary
└──────────────────────────────────┘
height: 52dp | radius: radiusM | bg: colorSurface
border default: 1.5dp colorDivider
border focus: 1.5dp colorPrimary
cursor: colorPrimary
```

#### Search Field

```
🔍  Поиск подписки...
height: 44dp | radius: radiusFull | bg: colorSurface
Нет рамки
```

#### OTP Field

```
[  0  ][  0  ][  0  ][  0  ][  0  ][  0  ]
Каждая ячейка: 44 × 52 dp | gap: 8dp | radius: radiusS
border default: 1.5dp colorDivider
border active: 2dp colorPrimary
```

#### Dropdown / Select

```
┌────────────────────────────── ▾ ┐
│  Ежемесячно                      │
└──────────────────────────────────┘
height: 52dp | radius: radiusM | bg: colorSurface
border: 1.5dp colorDivider
```

### 6.3 Pill Toggle (Активные / Архив)

```
╔═══════════════╦═══════════════╗
║   Активные    ║     Архив     ║
╚═══════════════╩═══════════════╝
```

| Состояние | bg пилюли | цвет текста |
|-----------|-----------|----|
| Активная | `#1A1A1A` (чёрный) | белый |
| Неактивная | прозрачно | `colorTextSecondary` |

Контейнер: height 40dp, `radiusFull`, bg `colorSurface`, border 1dp `colorDivider`.

### 6.4 Карточки

#### Budget Card

```
╔═══════════════════════════════════════╗  bg: тёмный градиент
║  ТРАТЫ В МЕСЯЦ                        ║  overline, rgba(255,255,255,0.55)
║                                       ║
║  3 915 ₽                              ║  headlineMedium (32sp), белый
║  Активных подписок: 7                 ║  bodyMedium, rgba(255,255,255,0.70)
║  ─────────────────────────────────    ║  divider rgba(255,255,255,0.15)
║  В год        Средний чек  Следующее  ║  bodySmall, rgba(255,255,255,0.55)
║  46 980 ₽     559 ₽          ↕       ║  labelMedium, белый
╚═══════════════════════════════════════╝
radius: radiusL | padding: 20dp
```

#### Wallet Card (на дашборде, 50% ширины)

```
╔════════════════════╗  bg: оранжевый градиент
║  🪙 Кошелёк        ║  bodySmall, rgba(255,255,255,0.70)
║  1 250 ₽           ║  headlineSmall, белый
║  Хватит на 0.3 мес.║  bodySmall, rgba(255,255,255,0.70)
╚════════════════════╝
radius: radiusL | padding: 16dp
```

#### Wallet Card Full (экран Кошелёк, полная ширина)

```
╔═══════════════════════════════════════╗  bg: оранжевый градиент
║  ДОСТУПНО                             ║  overline, rgba(255,255,255,0.70)
║  1 250 ₽                              ║  headlineMedium, белый
║  Автопополнение: выключено            ║  bodyMedium, rgba(255,255,255,0.70)
║  ─────────────────────────────────    ║
║  [+ Пополнить]      [↺ Авто]          ║  кнопки-пилюли
╚═══════════════════════════════════════╝
radius: radiusL | padding: 20dp
```

#### Market Card (vs. рынок, 50% ширины)

```
╔════════════════════╗
║  📊 vs. рынок      ║  bodySmall, colorTextSecondary
║  +57%              ║  headlineSmall, colorError (если выше рынка)
║  ↑ выше среднего   ║  bodySmall, colorError
╚════════════════════╝
bg: colorSurface | radius: radiusL
```

#### Subscription List Item

```
╔────────────────────────────────────────────╗
│ [Аватар 40dp]  Netflix              799 ₽  │  height: 68dp
│                через 2д             /мес   │  titleLarge + bodySmall
╚────────────────────────────────────────────╝
padding H: 16dp
Разделитель: 1dp colorDivider, indent 68dp (под аватар)
«через Nd»: bodySmall, цвет по сроку (см. 2.4)
«/мес»: bodySmall, colorTextSecondary
```

#### Quick Action Buttons (дашборд)

```
╔═══════════╗ ╔═══════════╗ ╔═══════════╗ ╔═══════════╗
║     ⊕     ║ ║    📅     ║ ║    🕐     ║ ║    ↓      ║
║ Добавить  ║ ║Календарь  ║ ║ История   ║ ║  Экспорт  ║
╚═══════════╝ ╚═══════════╝ ╚═══════════╝ ╚═══════════╝
Каждая: flex 1 | height 64dp | radius radiusL | bg colorSurface
Иконка «Добавить»: colorPrimary, остальные: colorTextPrimary
Текст: labelSmall, colorTextSecondary
gap между кнопками: 8dp
```

#### Transaction List Item

```
╔─────────────────────────────────────────────────╗
│ [↓ icon]  Пополнение с карты **4242   + 1 000 ₽ │  height: 64dp
│            27 апреля                             │
╚─────────────────────────────────────────────────╝
Иконка-кружок ↓ (пополнение): bg colorSuccess 15%, иконка colorSuccess
Иконка-кружок ↑ (списание): bg colorError 15%, иконка colorError
Сумма пополнения: «+ 1 000 ₽», colorSuccess, labelMedium
Сумма списания: «− 799 ₽», colorError, labelMedium
```

### 6.5 Bottom Navigation Bar

```
[🏠]    [⊞]    [ FAB ]    [💳]    [👤]
Главная  Подписки           Кошелёк  Профиль
```

- Высота: 82 dp (с safe area).
- bg: `colorSurface`, border-top 1dp `colorDivider`.
- **FAB** — центральный элемент, поднят над навбаром (+8 dp). Диаметр 52 dp, bg `colorPrimary`, тень `0 4 12 rgba(242,83,10,0.40)`.
- Активный таб: иконка + текст `colorPrimary`.
- Неактивный таб: `colorTextSecondary`.

### 6.6 AppBar

Двухстрочный заголовок на каждом экране:

```
Добрый день 👋        ← bodySmall, colorTextSecondary (кэпшн)
Ваш бюджет            ← headlineLarge, colorTextPrimary
                 [🔔]  ← action icon
```

`elevation: 0`, `scrolledUnderElevation: 0`, фон `colorBackground`.

### 6.7 Bottom Sheet

```
╔══════════════════════════════════╗  ← radiusXL верхних углов
║  ─── (drag handle 32×4dp)        ║
║                                  ║
║  Новая подписка           [✕]    ║  headlineSmall + ghost close
║  Заполните данные о подписке     ║  bodyMedium, colorTextSecondary
║  ─────────────────────────────   ║
║  [Поля формы]                    ║
║                                  ║
║  [Отмена]      [Сохранить →]     ║
╚══════════════════════════════════╝
bg: colorSurface | dim: rgba(0,0,0,0.35)
Анимация: slide up 300ms easeOut
```

### 6.8 Чипы срока списания

```
╔══════════╗
║ через 1д ║
╚══════════╝
height: 20dp | padding H: 6dp | radius: radiusXS
```

| Срок | bg | text |
|------|----|------|
| 1–2 дня | `colorError` 12% | `colorError` |
| 3–7 дней | `colorPrimaryLight` | `colorPrimary` |
| 8–14 дней | `colorPrimaryLight` | `colorTextSecondary` |
| 15+ дней | `colorDivider` | `colorTextSecondary` |

### 6.9 Тост-уведомления

```
╔══════════════════════════════════════════╗
║  ✓  Подписка добавлена              [✕] ║
╚══════════════════════════════════════════╝
Позиция: снизу, 16dp над навбаром
height: 52dp | radius: radiusM
Тайм-аут: 3 сек | Анимация: slide up + fade 200ms
```

| Тип | bg | border |
|-----|----|--------|
| success | `colorSuccess` 10% | 1dp `colorSuccess` 30% |
| error | `colorError` 10% | 1dp `colorError` 30% |
| info | `colorSurface` | 1dp `colorDivider` |

### 6.10 Диалог подтверждения

```
╔══════════════════════════════════╗
║  Отменить подписку?              ║  headlineSmall
║  Подписка уйдёт в архив.         ║  bodyMedium, colorTextSecondary
║                                  ║
║  [   Назад   ]  [  Отменить  ]   ║  Ghost + Destructive Primary
╚══════════════════════════════════╝
radius: radiusXL | bg: colorSurface | padding: 24dp
```

### 6.11 Profile Menu Item

```
╔──────────────────────────────────────╗
│  Свои подписки                    ›  │  titleLarge  |  height: 60dp
│  Создавайте и продавайте             │  bodySmall, colorTextSecondary
╚──────────────────────────────────────╝
Все пункты в одной белой карточке-контейнере (radiusL).
Разделитель между пунктами: 1dp colorDivider, indent 16dp.
```

---

## 7. Экраны

### 7.1 Онбординг

```
AppBar: [Лого 28dp] «Мои Подписки» (titleLarge)
─────────────────────────────────────────────────────
[Иллюстрация — тёмный блок, 48% высоты]
─────────────────────────────────────────────────────
Все подписки в одном месте    displayLarge
Описание                      bodyLarge, colorTextSecondary
─────────────────────────────────────────────────────
● ○ ○   (pagination dots, 8dp)
─────────────────────────────────────────────────────
[Далее →]        Primary Button
[Пропустить]     Ghost Button
```

### 7.2 Аутентификация

**Экран телефона:**

```
AppBar: [Лого] «Мои Подписки»
[Большой пустой gap ~30% высоты]
Вход без пароля         displayMedium
Описание                bodyLarge, colorTextSecondary
─────────────────────
[Phone Field: +7 ________]
[☐ Согласен с политикой и офертой]   ← ссылки colorPrimary
[Получить код →]        Primary Button (fixed bottom)
```

**Экран кода:**

```
[← arrow-left]          Ghost AppBar Button
[Большой пустой gap]
Введите код             displayMedium
Отправили 6 цифр на +7...   bodyLarge, colorTextSecondary (номер bold)
─────────────────────
Лейбл «Код из SMS (демо: 123456)»   bodySmall, colorTextSecondary
[OTP Field: 0 0 0 0 0 0]
[↺ Отправить снова]     Secondary outlined button
[Войти →]               Primary Button (fixed bottom)
```

### 7.3 Дашборд

```
«Добрый день 👋» / «Ваш бюджет»  AppBar + [bell]
─────────────────────────────────────────────────
[Budget Card — полная ширина, тёмная]
─────────────────────────────────────────────────
Row gap 8dp:
  [Wallet Card — 50%]   [Market Card — 50%]
─────────────────────────────────────────────────
Row gap 8dp:
  [Добавить] [Календарь] [История] [Экспорт]
─────────────────────────────────────────────────
«Ближайшие списания»         [Все — colorPrimary]
  Subscription List Item × 4
─────────────────────────────────────────────────
«По категориям»
  Category Bar Item × N
```

### 7.4 Список подписок

```
«Всё под контролем» / «Подписки»  AppBar + [+]
─────────────────────────────────────────────────
[Search Field — округлённый, colorSurface]
[Активные | Архив]               Pill Toggle
─────────────────────────────────────────────────
ListView:
  Subscription List Item × N
```

### 7.5 Кошелёк

```
«Автоматические платежи» / «Кошелёк»  AppBar + [refresh]
─────────────────────────────────────────────────
[Wallet Card Full — полная ширина, оранжевый]
─────────────────────────────────────────────────
«Последние операции»    headlineSmall
  Transaction List Item × N
```

### 7.6 Профиль

```
«Ваш аккаунт» / «Профиль»  AppBar + [settings]
─────────────────────────────────────────────────
[Карточка профиля — colorSurface, radiusL, centred]
  [Аватар 60dp — оранжевый]
  Добрый пользователь     headlineSmall
  +7 888 888 88 88        bodyMedium, colorTextSecondary
─────────────────────────────────────────────────
«Разделы»               bodySmall UPPERCASE, colorTextSecondary
[Menu Card:
  Свои подписки →
  Кошелёк →
  История →
  Экспорт →
  Настройки →]
─────────────────────────────────────────────────
[← Выйти]               Ghost Button, colorError
```

---

## 8. Анимации и переходы

### 8.1 Переходы экранов

| Переход | Тип | Длительность | Кривая |
|---------|-----|--------------|--------|
| Push | Slide Left | 300ms | `easeOut` |
| Pop | Slide Right | 250ms | `easeIn` |
| Bottom Sheet открытие | Slide Up | 300ms | `easeOut` |
| Bottom Sheet закрытие | Slide Down | 250ms | `easeIn` |
| Диалог | Scale 0.92→1.0 + Fade | 200ms | `easeOut` |
| Смена таба навбара | Fade | 150ms | `linear` |
| Pill Toggle | Sliding pill | 200ms | `easeInOut` |

### 8.2 Микроанимации

| Элемент | Анимация |
|---------|----------|
| Кнопка (pressed) | Scale 1.0 → 0.97, 100ms |
| List Item (tap) | Ripple `colorPrimaryLight` |
| FAB (появление) | Scale 0 → 1.0, Spring |
| Budget Card число | AnimatedCounter при загрузке |
| OTP ячейка (fill) | Scale 1.0 → 1.08 → 1.0, 150ms |
| Тост | Slide Up + Fade In 200ms |

### 8.3 Skeleton Loading

```dart
// shimmer при загрузке списков
baseColor: AppColors.divider       // #E8E4DC
highlightColor: AppColors.background  // #EDEAE4
direction: LTR
cycleDuration: 1200ms
```

---

## 9. Тёмная тема

Заготовка для следующей версии:

| Светлый токен | Тёмный аналог |
|---------------|---------------|
| `colorBackground` `#EDEAE4` | `#141210` |
| `colorSurface` `#FFFFFF` | `#1E1C1A` |
| `colorSurfaceVariant` `#F5F3EF` | `#252220` |
| `colorDivider` `#E8E4DC` | `#2E2B28` |
| `colorTextPrimary` `#1A1A1A` | `#F0EDE8` |
| `colorTextSecondary` `#8A8580` | `#9E9A95` |
| `colorPrimary` | без изменений |
| Budget Card тёмный градиент | ещё темнее: `#0A0806` → `#1A0800` |

---

## 10. Токены Flutter (Dart)

### 10.1 AppColors

```dart
// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand
  static const Color primary      = Color(0xFFF2530A);
  static const Color primaryLight = Color(0xFFFFF0EA);
  static const Color primaryDark  = Color(0xFFC43D00);

  // Neutral
  static const Color background      = Color(0xFFEDEAE4);
  static const Color surface         = Color(0xFFFFFFFF);
  static const Color surfaceVariant  = Color(0xFFF5F3EF);
  static const Color divider         = Color(0xFFE8E4DC);
  static const Color textPrimary     = Color(0xFF1A1A1A);
  static const Color textSecondary   = Color(0xFF8A8580);
  static const Color textDisabled    = Color(0xFFC4C0BA);
  static const Color textOnPrimary   = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color error   = Color(0xFFEF4444);

  // Special surfaces
  static const LinearGradient budgetCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A0A00), Color(0xFF2D1500), Color(0xFF1A0A00)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient walletCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF2530A), Color(0xFFE04500)],
  );

  // Avatar palette
  static const List<Color> _avatarPalette = [
    Color(0xFFE50914), // red
    Color(0xFF1DB954), // green
    Color(0xFF147EFB), // blue
    Color(0xFFF2530A), // orange
    Color(0xFF8B5CF6), // violet
    Color(0xFF1A1A1A), // dark
    Color(0xFFFFDD2D), // yellow (текст — тёмный!)
    Color(0xFF06B6D4), // cyan
  ];

  static Color avatarBgFromName(String name) {
    if (name.isEmpty) return _avatarPalette[0];
    return _avatarPalette[name.codeUnitAt(0) % _avatarPalette.length];
  }

  /// Возвращает цвет текста для аватара в зависимости от яркости фона
  static Color avatarFgFromBg(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.5 ? textPrimary : textOnPrimary;
  }
}
```

### 10.2 AppSpacing

```dart
// lib/core/constants/app_spacing.dart
abstract class AppSpacing {
  static const double s4  = 4;
  static const double s8  = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  static const double screenH = 16; // горизонтальный паддинг экрана
}
```

### 10.3 AppRadius

```dart
// lib/core/constants/app_radius.dart
import 'package:flutter/material.dart';

abstract class AppRadius {
  static const double xs   = 4;
  static const double s    = 8;
  static const double m    = 12;
  static const double l    = 16;
  static const double xl   = 20;
  static const double full = 999;

  static BorderRadius get xsBr   => BorderRadius.circular(xs);
  static BorderRadius get sBr    => BorderRadius.circular(s);
  static BorderRadius get mBr    => BorderRadius.circular(m);
  static BorderRadius get lBr    => BorderRadius.circular(l);
  static BorderRadius get xlBr   => BorderRadius.circular(xl);
  static BorderRadius get fullBr => BorderRadius.circular(full);

  static BorderRadius get bottomSheet =>
      const BorderRadius.vertical(top: Radius.circular(xl));
}
```

### 10.4 AppTextStyles

```dart
// lib/core/constants/app_text_styles.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  static const _f = 'Inter';

  static const displayMedium = TextStyle(
    fontFamily: _f, fontSize: 24, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.25,
  );
  static const headlineLarge = TextStyle(
    fontFamily: _f, fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.30,
  );
  // headlineMedium — для крупных сумм в карточках
  static const headlineMedium = TextStyle(
    fontFamily: _f, fontSize: 32, fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary, height: 1.15,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const headlineSmall = TextStyle(
    fontFamily: _f, fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.38,
  );
  static const titleLarge = TextStyle(
    fontFamily: _f, fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const bodyLarge = TextStyle(
    fontFamily: _f, fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.50,
  );
  static const bodyMedium = TextStyle(
    fontFamily: _f, fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.45,
  );
  static const bodySmall = TextStyle(
    fontFamily: _f, fontSize: 11, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.36,
  );
  static const labelLarge = TextStyle(
    fontFamily: _f, fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );
  static const labelMedium = TextStyle(
    fontFamily: _f, fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary, letterSpacing: 0.3,
  );
  // overline — для лейблов типа «ТРАТЫ В МЕСЯЦ»
  static const overline = TextStyle(
    fontFamily: _f, fontSize: 10, fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
  );
}
```

### 10.5 AppTheme

```dart
// lib/core/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        disabledBackgroundColor: AppColors.textDisabled,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: AppTextStyles.labelLarge,
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(double.infinity, 44),
        textStyle: AppTextStyles.labelLarge
            .copyWith(color: AppColors.textPrimary),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      hintStyle: AppTextStyles.bodyLarge
          .copyWith(color: AppColors.textDisabled),
      labelStyle: AppTextStyles.bodyMedium,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: AppTextStyles.labelMedium,
      unselectedLabelStyle: AppTextStyles.labelMedium,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textDisabled),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.primaryLight
              : AppColors.divider),
    ),
  );
}
```

---

*Версия 2.0 · Обновлено по реальным скриншотам прототипа · «Мои Подписки» Flutter*
