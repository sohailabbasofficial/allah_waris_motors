import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 32),
              PinDots(length: _pin.length, hasError: _hasError),
              const SizedBox(height: 16),
              SizedBox(
                height: 24,
                child: _error == null
                    ? null
                    : Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              const Spacer(),
              PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}