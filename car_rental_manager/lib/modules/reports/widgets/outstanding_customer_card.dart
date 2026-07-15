import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../models/outstanding_customer.dart';

class OutstandingCustomerCard extends StatelessWidget {
  const OutstandingCustomerCard({
    super.key,
    required this.customer,
    this.onTap,
  });

  final OutstandingCustomer customer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.errorContainer,
                    foregroundColor: scheme.onErrorContainer,
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          customer.phone,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(customer.remainingBalance),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'Total',
                      value: CurrencyFormatter.format(customer.totalAmount),
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'Paid',
                      value: CurrencyFormatter.format(customer.totalPaid),
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'Remaining',
                      value:
                          CurrencyFormatter.format(customer.remainingBalance),
                      emphasize: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
