import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/premium_card.dart';
import '../models/backup_state.dart';

class GoogleAccountCard extends StatelessWidget {
  const GoogleAccountCard({
    super.key,
    required this.state,
    required this.onConnect,
    required this.onDisconnect,
  });

  final BackupState state;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;

  @override
  Widget build(BuildContext context) {
    final signedIn = state.isSignedIn &&
        (state.accountEmail?.isNotEmpty ?? false);
    final accent = signedIn ? AppColors.received : AppColors.brandGray;

    return PremiumCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            signedIn ? AppIcons.backup : AppIcons.warning,
            color: accent,
          ),
        ),
        title: Text(
          signedIn
              ? (state.accountDisplayName?.isNotEmpty == true
                  ? state.accountDisplayName!
                  : 'Google Drive connected')
              : 'Google Drive not connected',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          signedIn
              ? (state.accountEmail ?? '')
              : 'Owner Google account required for backup & restore',
        ),
        trailing: signedIn
            ? TextButton(
                onPressed: onDisconnect,
                child: const Text('Logout'),
              )
            : FilledButton(
                onPressed: onConnect,
                child: const Text('Connect'),
              ),
      ),
    );
  }
}
