import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/premium_card.dart';
import '../models/transaction_amount_addition_model.dart';
import '../models/transaction_model.dart';

/// Chronological amount-addition history for a transaction.
class TransactionAmountHistorySection extends StatelessWidget {
  const TransactionAmountHistorySection({
    super.key,
    required this.transaction,
    required this.additions,
  });

  final TransactionModel transaction;
  final List<TransactionAmountAdditionModel> additions;

  double get _originalAmount {
    if (additions.isEmpty) return transaction.totalAmount;
    final added = additions.fold<double>(0, (sum, e) => sum + e.amount);
    final original = transaction.totalAmount - added;
    return original < 0 ? 0 : original;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount History',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Each added amount is kept as a separate record.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        PremiumCard(
          child: _HistoryTile(
            title: 'Initial Amount',
            subtitle: dateFmt.format(transaction.createdAt),
            previousLabel: null,
            amountLabel: 'Initial',
            amount: _originalAmount,
            totalLabel: 'Starting Total',
            total: _originalAmount,
            notes: transaction.notes,
            addedBy: null,
            accent: AppColors.brandBlue,
          ),
        ),
        if (additions.isEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'No additional amounts yet. Use “Add Amount” to increase this bill.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ] else
          ...additions.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: PremiumCard(
                child: _HistoryTile(
                  title: 'Added Amount',
                  subtitle: dateFmt.format(entry.createdAt),
                  previousLabel: 'Previous Balance',
                  previous: entry.previousTotal,
                  amountLabel: 'Added Amount',
                  amount: entry.amount,
                  totalLabel: 'Current Total Balance',
                  total: entry.newTotal,
                  notes: entry.notes,
                  addedBy: entry.addedBy,
                  accent: colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.title,
    required this.subtitle,
    this.previousLabel,
    this.previous,
    required this.amountLabel,
    required this.amount,
    required this.totalLabel,
    required this.total,
    this.notes,
    this.addedBy,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String? previousLabel;
  final double? previous;
  final String amountLabel;
  final double amount;
  final String totalLabel;
  final double total;
  final String? notes;
  final String? addedBy;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(AppIcons.money, color: accent, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        if (addedBy != null && addedBy!.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            'By $addedBy',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (previousLabel != null && previous != null)
          _kv(context, previousLabel!, CurrencyFormatter.format(previous!)),
        _kv(
          context,
          amountLabel,
          CurrencyFormatter.format(amount),
          valueColor: accent,
        ),
        _kv(
          context,
          totalLabel,
          CurrencyFormatter.format(total),
          valueColor: AppColors.remaining,
          bold: true,
        ),
        if (notes != null && notes!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            notes!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  Widget _kv(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: valueColor,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
