import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/pin_dots.dart';
import '../../../core/widgets/pin_keypad.dart';
import '../../../routes/app_routes.dart';
import '../providers/auth_providers.dart';

/// PIN login screen with optional biometric unlock.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _pin = '';
  String? _error;
  bool _hasError = false;
  bool _locked = false;
  Duration _lockRemaining = Duration.zero;
  Timer? _lockTimer;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLockState();
      _maybePromptBiometric();
    });
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  void _syncLockState() {
    final service = ref.read(pinServiceProvider);
    final remaining = service.lockRemaining();
    if (remaining > Duration.zero) {
      _startLockCountdown(remaining);
    }
  }

  void _startLockCountdown(Duration remaining) {
    _lockTimer?.cancel();
    setState(() {
      _locked = true;
      _lockRemaining = remaining;
      _pin = '';
      _error =
          'Too many attempts. Try again in ${remaining.inSeconds}s.';
      _hasError = true;
    });
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = ref.read(pinServiceProvider).lockRemaining();
      if (left <= Duration.zero) {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          _locked = false;
          _lockRemaining = Duration.zero;
          _error = null;
          _hasError = false;
        });
      } else if (mounted) {
        setState(() {
          _lockRemaining = left;
          _error = 'Too many attempts. Try again in ${left.inSeconds}s.';
        });
      }
    });
  }

  Future<void> _maybePromptBiometric() async {
    final enabled = ref.read(biometricEnabledProvider);
    final available =
        await ref.read(biometricAvailableProvider.future);
    if (!enabled || !available || !mounted || _locked) return;
    await _authenticateBiometric();
  }

  Future<void> _authenticateBiometric() async {
    if (_authenticating || _locked) return;
    setState(() => _authenticating = true);
    final ok = await ref.read(biometricServiceProvider).authenticate();
    if (!mounted) return;
    setState(() => _authenticating = false);
    if (ok) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
    // On failure, stay on PIN entry (requirement).
  }

  void _onDigit(String digit) {
    if (_locked || _pin.length >= AppConstants.pinLength) return;
    setState(() {
      _pin += digit;
      _error = null;
      _hasError = false;
    });
    if (_pin.length == AppConstants.pinLength) {
      _submit();
    }
  }

  void _onBackspace() {
    if (_locked || _pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
      _hasError = false;
    });
  }

  Future<void> _submit() async {
    final result = await ref.read(pinServiceProvider).verifyPin(_pin);
    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      return;
    }
    setState(() {
      _pin = '';
      _error = result.errorMessage;
      _hasError = true;
    });
    if (result.isLocked) {
      _startLockCountdown(result.lockRemaining);
    }
  }

  @override
  Widget build(BuildContext context) {
    final biometricAsync = ref.watch(biometricAvailableProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final showFingerprint = biometricEnabled &&
        biometricAsync.maybeWhen(data: (v) => v, orElse: () => false);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _locked
                    ? 'Locked — ${_lockRemaining.inSeconds}s remaining'
                    : 'Enter your PIN',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              PinDots(length: _pin.length, hasError: _hasError),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
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
              if (showFingerprint) ...[
                const SizedBox(height: 8),
                IconButton.filledTonal(
                  onPressed: _locked || _authenticating
                      ? null
                      : _authenticateBiometric,
                  iconSize: 36,
                  icon: _authenticating
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.fingerprint),
                  tooltip: 'Unlock with fingerprint',
                ),
                const Text('Use fingerprint'),
              ],
              const Spacer(),
              PinKeypad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                enabled: !_locked,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}