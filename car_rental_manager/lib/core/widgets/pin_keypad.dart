import 'package:flutter/material.dart';

import '../utils/responsive.dart';

/// Numeric keypad for 4-digit PIN entry — scales for all mobile ratios.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final keySize = r.pinKeySize;
    final spacing = r.pinKeySpacing;
    final keys = <List<String?>>[
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [null, '0', 'back'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: keys.map((row) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: spacing),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key == null) {
                return SizedBox(width: keySize, height: keySize);
              }
              if (key == 'back') {
                return _KeyCircle(
                  size: keySize,
                  onTap: enabled ? onBackspace : null,
                  child: Icon(
                    Icons.backspace_outlined,
                    size: keySize * 0.36,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                );
              }
              return _KeyCircle(
                size: keySize,
                onTap: enabled ? () => onDigit(key) : null,
                child: Text(
                  key,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: keySize * 0.36,
                      ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeyCircle extends StatelessWidget {
  const _KeyCircle({
    required this.child,
    required this.size,
    this.onTap,
  });

  final Widget child;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}
