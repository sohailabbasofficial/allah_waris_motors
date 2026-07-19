import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Breakpoints and sizing helpers for phones, phablets, and tablets.
class Responsive {
  Responsive._(this.size, this.shortestSide, this.orientation);

  factory Responsive.of(BuildContext context) {
    final media = MediaQuery.of(context);
    return Responsive._(media.size, media.size.shortestSide, media.orientation);
  }

  final Size size;
  final double shortestSide;
  final Orientation orientation;

  bool get isPhone => shortestSide < 600;
  bool get isTablet => shortestSide >= 600;
  bool get isLandscape => orientation == Orientation.landscape;

  double get width => size.width;
  double get height => size.height;

  /// Horizontal page padding scaled for device width.
  double get pagePadding {
    if (width >= 1100) return 32;
    if (width >= 800) return AppSpacing.pagePaddingWide;
    if (width <= 340) return 12;
    return AppSpacing.pagePadding;
  }

  EdgeInsets get pageInsets => EdgeInsets.symmetric(
        horizontal: pagePadding,
        vertical: isLandscape ? AppSpacing.sm : AppSpacing.lg,
      );

  /// Soft max width for readable forms on large screens / web.
  double get contentMaxWidth {
    if (width >= 1200) return 960;
    if (width >= 900) return 820;
    return width;
  }

  double get logoHeight {
    if (isLandscape) return height * 0.22;
    if (height < 640) return 96;
    if (height < 720) return 120;
    if (width < 360) return 140;
    return 168;
  }

  double get pinKeySize {
    if (isLandscape) return 52;
    if (shortestSide < 340) return 56;
    if (shortestSide < 380) return 64;
    return 72;
  }

  double get pinKeySpacing {
    if (isLandscape || height < 640) return 4;
    return 6;
  }

  int statsCrossAxisCount() {
    if (width >= 1100) return 5;
    if (width >= 820) return 3;
    if (width >= 360) return 2;
    return 1;
  }

  double statsChildAspectRatio() {
    final cols = statsCrossAxisCount();
    if (cols >= 5) return 2.0;
    if (cols >= 3) return 1.75;
    if (cols == 2) {
      // Lower ratio = taller cells (avoids overflow on narrow phones).
      if (width < 400) return 1.15;
      if (width < 480) return 1.25;
      return 1.4;
    }
    return 1.9;
  }

  /// Fixed row height for overview cards — more reliable than aspect ratio alone.
  double statsMainAxisExtent() {
    final cols = statsCrossAxisCount();
    if (cols == 1) return 118;
    if (cols == 2) {
      if (width < 360) return 126;
      if (width < 400) return 132;
      return 136;
    }
    if (cols >= 3) return 122;
    return 128;
  }

  int quickActionsCrossAxisCount() {
    if (width >= 900) return 4;
    if (width >= 560) return 2;
    if (width >= 360) return 2;
    return 1;
  }

  double quickActionsChildAspectRatio() {
    final cols = quickActionsCrossAxisCount();
    if (cols >= 4) return 1.2;
    if (cols == 2) {
      if (width < 400) return 1.2;
      return 1.4;
    }
    return 2.5;
  }

  int reportsCrossAxisCount() => width >= 800 ? 2 : 1;

  /// Wrap scrollable body and optionally constrain width on large screens.
  static Widget constrain({
    required BuildContext context,
    required Widget child,
  }) {
    final r = Responsive.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: r.contentMaxWidth),
        child: child,
      ),
    );
  }
}
