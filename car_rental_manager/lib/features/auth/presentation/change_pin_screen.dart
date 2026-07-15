import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/pin_dots.dart';
import '../../../core/widgets/pin_keypad.dart';
import '../providers/auth_providers.dart';

enum _ChangeStep { current, create, confirm }

/// Change PIN: verify current, then create and confirm a new PIN.
class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  _ChangeStep _step = _ChangeStep.current;
  String _pin = '';
  String _newPin = '';
  String? _error;
  bool _hasError = false;

  String get _title {
    switch (_step) {
      case _ChangeStep.current:
        return 'Enter Current PIN';
      case _ChangeStep.create:
        return 'Enter New PIN';
      case _ChangeStep.confirm:
        return 'Confirm New PIN';
    }
  }

  String get _subtitle {
    switch (_step) {
      case _ChangeStep.current:
        return 'Verify your current PIN to continue';
      case _ChangeStep.create:
        return 'Choose a new 4-digit PIN';
      case _ChangeStep.confirm:
        return 'Re-enter the new PIN to confirm';
    }
  }

  void _onDigit(String digit) {
    if (_pin.length >= AppConstants.pinLength) return;
    setState(() {
      _pin += digit;
      _error = null;
      _hasError = false;
    });
    if (_pin.length == AppConstants.pinLength) {
      _onComplete();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
      _hasError = false;
    });
  }

  Future<void> _onComplete() async {
    final pinService = ref.read(pinServiceProvider);

    if (_step == _ChangeStep.current) {
      final result = await pinService.verifyPin(_pin);
      if (!mounted) return;
      if (!result.success) {
        setState(() {
          _pin = '';
          _error = result.errorMessage ?? 'Incorrect PIN';
          _hasError = true;
        });
        return;
      }
      setState(() {
        _pin = '';
        _step = _ChangeStep.create;
      });
      return;
    }

    if (_step == _ChangeStep.create) {
      setState(() {
        _newPin = _pin;
        _pin = '';
        _step = _ChangeStep.confirm;
      });
      return;
    }

    if (_pin != _newPin) {
      setState(() {
        _error = 'PINs do not match. Try again.';
        _hasError = true;
        _pin = '';
        _newPin = '';
        _step = _ChangeStep.create;
      });
      return;
    }

    await pinService.savePin(_pin);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN changed successfully')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = Responsive.of(context);
    final iconSize = r.height < 640 ? 48.0 : 64.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: r.pagePadding),
            child: Icon(AppIcons.pin, color: scheme.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: r.pageInsets,
          child: Responsive.constrain(
            context: context,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: r.isLandscape ? 4 : 12),
                        Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.security,
                            color: scheme.primary,
                            size: iconSize * 0.48,
                          ),
                        ),
                        SizedBox(height: r.isLandscape ? 8 : 16),
                        Text(
                          _subtitle,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                        SizedBox(height: r.isLandscape ? 16 : 28),
                        PinDots(length: _pin.length, hasError: _hasError),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 28,
                          child: _error == null
                              ? null
                              : Text(
                                  _error!,
                                  style: TextStyle(color: scheme.error),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
