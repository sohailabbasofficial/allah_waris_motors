import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      leading: CircleAvatar(
        backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
        foregroundColor: colorScheme.primary,
        child: Text(
          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      title: Text(
        customer.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Row(
        children: [
          Icon(
            AppIcons.phone,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              customer.phone.isEmpty ? 'No phone' : customer.phone,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.remaining,
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
              child: const Text('View'),
            ),
          ],
        ),
      ),
      onTap: onViewDetails,
    );
  }
}
