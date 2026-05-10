import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'subscription_provider.dart'; // нужен monthlyCostProvider

// Предполагаемая средняя рыночная стоимость подписок (можно вынести в конфиг)
const double averageMarketMonthlyCost = 2500.0;

final marketComparisonProvider = Provider<MarketComparison>((ref) {
  final monthlyCost = ref.watch(monthlyCostProvider);
  final percent = monthlyCost > 0
      ? ((averageMarketMonthlyCost - monthlyCost) / monthlyCost * 100).round()
      : 0;
  return MarketComparison(percent: percent);
});

class MarketComparison {
  final int percent;
  const MarketComparison({required this.percent});
}
