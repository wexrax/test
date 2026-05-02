extension DateTimeFormatting on DateTime {
  String get dayMonth {
    return '$day ${_monthName(month)}';
  }
  String get shortDate {
    return '$day.${month.toString().padLeft(2, '0')}.$year';
  }
  String _monthName(int month) {
    const months = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return months[month - 1];
  }
  String relativeToNow() {
    final now = DateTime.now();
    final diff = difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Сегодня';
    if (diff == 1) return 'Завтра';
    if (diff > 1 && diff <= 7) return 'Через $diff дн.';
    return dayMonth;
  }
}

String monthName(int month) {
  const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
  return months[month - 1];
}

DateTime nextPaymentDateFromPeriod(String period, DateTime current) {
  switch (period) {
    case 'monthly':
      return DateTime(current.year, current.month + 1, current.day);
    case 'yearly':
      return DateTime(current.year + 1, current.month, current.day);
    default:
      return current.add(const Duration(days: 30));
  }
}