import 'package:flutter/material.dart';

class TransactionInfoTile extends StatelessWidget {
  const TransactionInfoTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: icon == null
          ? null
          : CircleAvatar(
              backgroundColor: colorScheme.surfaceContainerHighest,
              child: Icon(icon, color: colorScheme.primary),
            ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
      ),
    );
  }
}
