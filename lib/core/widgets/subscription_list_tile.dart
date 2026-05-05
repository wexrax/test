// lib/core/widgets/subscription_list_tile.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/currency_utils.dart';
import '../utils/date_utils.dart';
import '../../presentation/providers/subscription_provider.dart';

class SubscriptionListTile extends StatelessWidget {
  final SubscriptionData subscription;
  final VoidCallback onTap;

  const SubscriptionListTile({
    super.key,
    required this.subscription,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: _colorForLetter(subscription.iconLetter),
          child: Text(
            subscription.iconLetter,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          subscription.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          'Следующее: ${subscription.nextPaymentDate.relativeToNow()}',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              subscription.amount.rub,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              subscription.period == 'monthly' ? 'мес' : 'год',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForLetter(String letter) {
    final code = letter.isNotEmpty ? letter.codeUnitAt(0) : 65;
    const colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.walletBlue,
      AppColors.danger,
      Colors.orange,
    ];
    return colors[code % colors.length];
  }
}