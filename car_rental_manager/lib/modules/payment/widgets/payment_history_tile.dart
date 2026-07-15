import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/payment_model.dart';

class PaymentHistoryTile extends StatelessWidget {
  const PaymentHistoryTile({
    super.key,
    required this.payment,
    this.onTap,
  });

  final PaymentModel payment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = DateFormat('dd MMM yyyy').format(payment.paymentDate);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.received.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          AppIcons.payments,
          color: AppColors.received,
          size: 22,
        ),
      ),
      title: Text(
        payment.customerName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Row(
        children: [
          Icon(
            AppIcons.calendar,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(date),
        ],
      ),
      trailing: Text(
        CurrencyFormatter.format(payment.paymentAmount),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.received,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
