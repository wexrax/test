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
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _colorForLetter(subscription.iconLetter),
        child: Text(
          subscription.iconLetter,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(subscription.name),
      subtitle: Text(
        'Следующее: ${subscription.nextPaymentDate.relativeToNow()}',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            subscription.amount.rub,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            subscription.period == 'monthly' ? 'мес' : 'год',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
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