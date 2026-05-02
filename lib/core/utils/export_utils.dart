import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SubscriptionCsvRow {
  const SubscriptionCsvRow({
    required this.name,
    required this.category,
    required this.amount,
    required this.period,
    required this.nextPaymentDate,
    required this.status,
  });

  final String name;
  final String category;
  final double amount;
  final String period;
  final DateTime nextPaymentDate;
  final String status;
}

String buildSubscriptionsCsv(Iterable<SubscriptionCsvRow> subscriptions) {
  return const ListToCsvConverter().convert([
    [
      'Название',
      'Категория',
      'Сумма',
      'Период',
      'Следующее списание',
      'Статус',
    ],
    ...subscriptions.map((subscription) => [
          subscription.name,
          subscription.category,
          subscription.amount.toStringAsFixed(2),
          subscription.period,
          subscription.nextPaymentDate.toIso8601String(),
          subscription.status,
        ]),
  ]);
}

Future<void> shareCsvFile(String csvContent, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(csvContent);
  await Share.shareXFiles([XFile(file.path)], text: fileName);
}
