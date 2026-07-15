import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _AmountChip(
                label: 'Total',
                value: CurrencyFormatter.format(totalAmount),
                color: colorScheme.primary,
              ),
            ),
            Expanded(
              child: _AmountChip(
                label: 'Received',
                value: CurrencyFormatter.format(receivedAmount),
                color: const Color(0xFF2E7D32),
              ),
            ),
            Expanded(
              child: _AmountChip(
                label: 'Remaining',
                value: CurrencyFormatter.format(remainingAmount),
                color: colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
