import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: colorScheme.tertiaryContainer,
        foregroundColor: colorScheme.onTertiaryContainer,
        child: const Icon(Icons.payments_outlined),
      ),
      title: Text(
        transaction.customerName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        method == null || method.isEmpty ? dateLabel : '$dateLabel · $method',
      ),
      trailing: Text(
        CurrencyFormatter.format(transaction.amount),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
