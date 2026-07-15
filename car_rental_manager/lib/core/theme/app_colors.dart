import 'package:flutter/material.dart';

/// Official Allah Waris Motors brand palette.
///
/// Prefer these constants everywhere. Semantic aliases keep existing call sites
/// consistent without inventing extra hues.
abstract final class AppColors {
  // —— Official palette ——
  static const Color primary = Color(0xFF0D47A1);
  static const Color secondary = Color(0xFF1976D2);
  static const Color accent = Color(0xFF42A5F5);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F7FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);

  static const Color textPrimary = Color(0xFF102A43);
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color icon = Color(0xFF1565C0);
  static const Color border = Color(0xFFD6E4F0);

  /// Soft blue wash for gradients / icon chips.
  static const Color mist = Color(0xFFE8F1FB);

  /// Portal dashboard card accents (solid icon tiles).
  static const Color cardBlue = Color(0xFF3B82F6);
  static const Color cardAmber = Color(0xFFF59E0B);
  static const Color cardGreen = Color(0xFF22C55E);
  static const Color cardPurple = Color(0xFF8B5CF6);
  static const Color portalSurface = Color(0xFFF9FAFB);

  // —— Compatibility aliases (map old names → official palette) ——
  static const Color brandBlue = primary;
  static const Color brandBlueLight = secondary;
  static const Color brandGray = textSecondary;
  static const Color brandSurface = surface;
  static const Color brandMist = mist;

  /// Blue-family accents for stats / nav (no purple/orange/pink).
  static const Color customers = secondary;
  static const Color today = accent;

  /// Semantic money states.
  static const Color udhaar = warning;
  static const Color received = success;
  static const Color remaining = error;

  /// Subtle blue steps for dashboard statistic cards.
  static const Color statBlue1 = primary;
  static const Color statBlue2 = secondary;
  static const Color statBlue3 = icon;
  static const Color statBlue4 = accent;
  static const Color statBlue5 = Color(0xFF1565C0);
}
