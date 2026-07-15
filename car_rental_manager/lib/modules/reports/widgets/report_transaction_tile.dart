import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/premium_card.dart';
import '../models/report_transaction_row.dart';

class ReportTransactionTile extends StatelessWidget {
  const ReportTransactionTile({super.key, required this.transaction});

  final ReportTransactionRow transaction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            AppIcons.transactions,
            color: scheme.primary,
            size: AppSpacing.iconSize,
          ),
        ),
        title: Text(
          transaction.customerName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${DateFormat('dd MMM yyyy').format(transaction.date)} · '
          '${transaction.description}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(transaction.totalAmount),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              'Paid ${CurrencyFormatter.format(transaction.receivedAmount)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
