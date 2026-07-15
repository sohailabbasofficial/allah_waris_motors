import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Professional summary/stat card — fits any cell height without overflow.
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.footer,
    this.footerColor,
    this.index = 0,
  });

  final String title;
  final String value;
  final String? subtitle;
  final String? footer;
  final Color? footerColor;
  final IconData icon;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 340 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Material(
        color: isDark ? const Color(0xFF1A2230) : AppColors.card,
        elevation: isDark ? 0 : 2,
        shadowColor: const Color(0x14000000),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final compact = h > 0 && h < 128;
              final veryCompact = h > 0 && h < 108;
              final pad = compact ? 12.0 : 16.0;
              final iconSize = veryCompact ? 36.0 : (compact ? 40.0 : 48.0);
              final gap = veryCompact ? 2.0 : (compact ? 4.0 : 6.0);
              final titleStyle =
                  Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 12.5 : 13.5,
                        height: 1.15,
                      );
              final valueStyle =
                  Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        fontSize: veryCompact ? 18 : (compact ? 20 : 22),
                        height: 1.1,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      );

              return Padding(
                padding: EdgeInsets.all(pad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth - pad * 2 - iconSize - (compact ? 8 : 12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle,
                              ),
                              SizedBox(height: gap),
                              Text(value, style: valueStyle),
                              if (subtitle != null && !veryCompact) ...[
                                SizedBox(height: gap),
                                Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: compact ? 11 : 12,
                                        height: 1.2,
                                      ),
                                ),
                              ],
                              if (footer != null) ...[
                                SizedBox(height: compact ? 4 : 8),
                                Text(
                                  footer!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color:
                                            footerColor ?? AppColors.cardGreen,
                                        fontWeight: FontWeight.w600,
                                        fontSize: compact ? 11 : 12,
                                        height: 1.15,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 12),
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: iconSize * 0.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
