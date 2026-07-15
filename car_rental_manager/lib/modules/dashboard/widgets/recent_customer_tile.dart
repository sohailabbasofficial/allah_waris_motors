import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../models/recent_customer.dart';

/// List tile for a recent customer on the dashboard.
class RecentCustomerTile extends StatelessWidget {
  const RecentCustomerTile({
    super.key,
    required this.customer,
    this.onViewDetails,
  });

  final RecentCustomer customer;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        child: Text(
          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        customer.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        customer.phone.isEmpty ? 'No phone' : customer.phone,
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyFormatter.format(customer.remainingBalance),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colorScheme.error,
                fontSize: 13,
              ),
            ),
            TextButton(
              onPressed: onViewDetails,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
              ),
              child: const Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }
}
