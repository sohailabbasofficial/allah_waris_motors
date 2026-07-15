import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/recent_transaction.dart';

/// List tile for a recent payment on the dashboard.
class RecentTransactionTile extends StatelessWidget {
  const RecentTransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  final RecentTransaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateLabel = DateFormat('dd MMM yyyy').format(transaction.paidAt);
    final method = transaction.paymentMethod?.trim();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.received.withValues(alpha: 0.12),
        foregroundColor: AppColors.received,
        child: const Icon(AppIcons.payments, size: 20),
      ),
      title: Text(
        transaction.customerName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        method == null || method.isEmpty ? dateLabel : '$dateLabel · $method',
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: Text(
        CurrencyFormatter.format(transaction.amount),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.received,
        ),
      ),
    );
  }
}
