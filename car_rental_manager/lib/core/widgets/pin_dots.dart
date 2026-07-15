import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Displays filled/empty dots representing entered PIN digits.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    this.hasError = false,
  });

  final int length;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = hasError ? colorScheme.error : colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(AppConstants.pinLength, (index) {
        final filled = index < length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? active : Colors.transparent,
            border: Border.all(
              color: hasError ? colorScheme.error : colorScheme.outline,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}