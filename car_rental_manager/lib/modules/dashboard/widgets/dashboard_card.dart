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
              final w = constraints.maxWidth;
              final compact = h > 0 && h < 128 || w < 160;
              final veryCompact = h > 0 && h < 108 || w < 140;
              final pad = compact ? 10.0 : 14.0;
              final iconSize = veryCompact ? 32.0 : (compact ? 38.0 : 46.0);
              final gap = veryCompact ? 2.0 : (compact ? 4.0 : 6.0);
              final titleStyle =
                  Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 12 : 13.5,
                        height: 1.15,
                      );
              final valueStyle =
                  Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        fontSize: veryCompact ? 17 : (compact ? 19 : 22),
                        height: 1.05,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      );

              return Padding(
                padding: EdgeInsets.all(pad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                          SizedBox(height: gap),
                          // Long amounts shrink to one line (never wrap).
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value,
                              maxLines: 1,
                              softWrap: false,
                              style: valueStyle,
                            ),
                          ),
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
                                    fontSize: compact ? 10.5 : 12,
                                    height: 1.2,
                                  ),
                            ),
                          ],
                          if (footer != null) ...[
                            SizedBox(height: compact ? 4 : 6),
                            Text(
                              footer!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: footerColor ?? AppColors.cardGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: compact ? 10.5 : 12,
                                    height: 1.15,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 10),
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
