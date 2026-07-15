import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/premium_card.dart';
import '../models/ledger_entry.dart';

class CustomerLedgerCard extends StatelessWidget {
  const CustomerLedgerCard({super.key, required this.entry});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPayment = entry.type == LedgerEntryType.payment;
    final color = isPayment ? AppColors.received : scheme.primary;

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
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isPayment ? AppIcons.payments : AppIcons.transactions,
            color: color,
            size: AppSpacing.iconSize,
          ),
        ),
        title: Text(
          entry.description,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            DateFormat('dd MMM yyyy').format(entry.date),
            if (entry.notes != null && entry.notes!.trim().isNotEmpty)
              entry.notes!,
          ].join(' · '),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (entry.debit > 0)
              Text(
                '+ ${CurrencyFormatter.format(entry.debit)}',
                style: const TextStyle(
                  color: AppColors.remaining,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (entry.credit > 0)
              Text(
                '- ${CurrencyFormatter.format(entry.credit)}',
                style: const TextStyle(
                  color: AppColors.received,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Text(
              'Bal ${CurrencyFormatter.format(entry.runningBalance)}',
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
