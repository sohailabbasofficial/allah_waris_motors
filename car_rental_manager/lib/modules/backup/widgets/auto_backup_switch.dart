import 'package:flutter/material.dart';

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
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.schedule_outlined),
            title: const Text('Automatic daily backup'),
            subtitle: const Text('Runs once a day when signed in'),
            value: enabled,
            onChanged: enabledControls ? onEnabledChanged : null,
          ),
          const Divider(height: 1),
          ListTile(
            enabled: enabled && enabledControls,
            leading: const Icon(Icons.access_time),
            title: const Text('Backup time'),
            subtitle: Text(timeLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: enabled && enabledControls ? onPickTime : null,
          ),
        ],
      ),
    );
  }
}
