import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/premium_card.dart';

class AutoBackupSwitch extends StatelessWidget {
  const AutoBackupSwitch({
    super.key,
    required this.enabled,
    required this.timeLabel,
    required this.onEnabledChanged,
    required this.onPickTime,
    this.enabledControls = true,
  });

  final bool enabled;
  final String timeLabel;
  final ValueChanged<bool>? onEnabledChanged;
  final VoidCallback? onPickTime;
  final bool enabledControls;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PremiumCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(AppIcons.calendar, color: scheme.primary),
            ),
            title: const Text('Automatic daily backup'),
            subtitle: const Text('Runs once a day when signed in'),
            value: enabled,
            onChanged: enabledControls ? onEnabledChanged : null,
          ),
          const Divider(height: 1),
          ListTile(
            enabled: enabled && enabledControls,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(AppIcons.today, color: scheme.primary),
            ),
            title: const Text('Backup time'),
            subtitle: Text(timeLabel),
            trailing: const Icon(AppIcons.chevron),
            onTap: enabled && enabledControls ? onPickTime : null,
          ),
        ],
      ),
    );
  }
}
