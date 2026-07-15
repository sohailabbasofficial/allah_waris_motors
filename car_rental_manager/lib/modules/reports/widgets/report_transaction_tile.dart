import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/currency_formatter.dart';
import '../models/report_transaction_row.dart';

class ReportTransactionTile extends StatelessWidget {
  const ReportTransactionTile({super.key, required this.transaction});

  final ReportTransactionRow transaction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          child: const Icon(Icons.receipt_long_outlined),
        ),
        title: Text(transaction.customerName),
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
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
