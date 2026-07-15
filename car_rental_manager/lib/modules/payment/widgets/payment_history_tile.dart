import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(Icons.payments_outlined,
            color: colorScheme.onPrimaryContainer),
      ),
      title: Text(
        payment.customerName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(date),
      trailing: Text(
        CurrencyFormatter.format(payment.paymentAmount),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
