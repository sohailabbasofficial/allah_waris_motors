import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/pin_dots.dart';
import '../../../core/widgets/pin_keypad.dart';
import '../../../routes/app_routes.dart';
import '../providers/auth_providers.dart';

/// First-launch (or post-reset) flow: create PIN, then confirm it.
class CreatePinScreen extends ConsumerStatefulWidget {
  const CreatePinScreen({super.key});

  @override
  ConsumerState<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends ConsumerState<CreatePinScreen> {
  String _firstPin = '';
  String _pin = '';
  bool _confirming = false;
  String? _error;
  bool _hasError = false;

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
    if (!_confirming) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _confirming = true;
      });
      return;
    }

    if (_pin != _firstPin) {
      setState(() {
        _error = 'PINs do not match. Try again.';
        _hasError = true;
        _pin = '';
        _firstPin = '';
        _confirming = false;
      });
      return;
    }

    await ref.read(pinServiceProvider).savePin(_pin);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _confirming ? 'Confirm PIN' : 'Create PIN';
    final subtitle = _confirming
        ? 'Re-enter your 4-digit PIN'
        : 'Choose a 4-digit PIN to secure the app';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
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