import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

/// Branded logo image used across splash, auth, and headers.
///
/// [logo.png] already includes the car mark + "ALLAH WARIS MOTORS" + tagline.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 180,
    this.width,
    this.heroTag,
    this.iconOnly = false,
  });

  final double height;
  final double? width;
  final String? heroTag;

  /// When true, crops to the car/AW mark at the top of the asset.
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      AppAssets.logo,
      width: width,
      height: iconOnly ? height / 0.48 : height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      alignment: Alignment.topCenter,
    );

    if (iconOnly) {
      image = SizedBox(
        width: width ?? height,
        height: height,
        child: ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 0.48,
            child: image,
          ),
        ),
      );
    }

    if (heroTag == null) return image;
    return Hero(tag: heroTag!, child: image);
  }
}
