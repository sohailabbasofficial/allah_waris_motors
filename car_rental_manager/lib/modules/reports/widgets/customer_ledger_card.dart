import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/currency_formatter.dart';
import '../models/ledger_entry.dart';

class CustomerLedgerCard extends StatelessWidget {
  const CustomerLedgerCard({super.key, required this.entry});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPayment = entry.type == LedgerEntryType.payment;
    final color = isPayment ? scheme.primary : scheme.tertiary;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Icon(
            isPayment ? Icons.payments_outlined : Icons.receipt_long_outlined,
          ),
        ),
        title: Text(entry.description),
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
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (entry.credit > 0)
              Text(
                '- ${CurrencyFormatter.format(entry.credit)}',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            Text(
              'Bal ${CurrencyFormatter.format(entry.runningBalance)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
