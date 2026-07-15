import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/premium_card.dart';

/// Live total / received / remaining summary for the form.
class AmountSummaryCard extends StatelessWidget {
  const AmountSummaryCard({
    super.key,
    required this.totalAmount,
    required this.receivedAmount,
    required this.remainingAmount,
  });

  final double totalAmount;
  final double receivedAmount;
  final double remainingAmount;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: _AmountChip(
              icon: AppIcons.money,
              label: 'Total',
              value: CurrencyFormatter.format(totalAmount),
              color: AppColors.brandBlue,
            ),
          ),
          Expanded(
            child: _AmountChip(
              icon: AppIcons.received,
              label: 'Received',
              value: CurrencyFormatter.format(receivedAmount),
              color: AppColors.received,
            ),
          ),
          Expanded(
            child: _AmountChip(
              icon: AppIcons.remaining,
              label: 'Remaining',
              value: CurrencyFormatter.format(remainingAmount),
              color: AppColors.remaining,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
