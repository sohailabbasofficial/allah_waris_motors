import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/pin_dots.dart';
import '../../../core/widgets/pin_keypad.dart';
import '../../../modules/backup/providers/backup_provider.dart';
import '../../../routes/app_routes.dart';
import '../providers/auth_providers.dart';
import '../providers/google_session_provider.dart';

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
      _error = 'Too many attempts. Try again in ${remaining.inSeconds}s.';
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
    final available = await ref.read(biometricAvailableProvider.future);
    if (!enabled || !available || !mounted || _locked) return;
    await _authenticateBiometric();
  }

  Future<bool> _ensureAuthorizedGoogle() async {
    final ok =
        await ref.read(backupRepositoryProvider).isAuthorizedSession();
    ref.invalidate(authorizedGoogleSessionProvider);
    if (!mounted) return false;
    if (!ok) {
      await ref.read(biometricEnabledProvider.notifier).setEnabled(false);
      if (!mounted) return false;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.googleSignIn,
        (route) => false,
        arguments: const {'asGate': true},
      );
      return false;
    }
    return true;
  }

  Future<void> _goHome() async {
    if (!await _ensureAuthorizedGoogle()) return;
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  Future<void> _authenticateBiometric() async {
    if (_authenticating || _locked) return;
    if (!await _ensureAuthorizedGoogle()) return;
    if (!mounted) return;
    setState(() => _authenticating = true);
    final ok = await ref.read(biometricServiceProvider).authenticate();
    if (!mounted) return;
    setState(() => _authenticating = false);
    if (ok) {
      await _goHome();
    }
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
      await _goHome();
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
    final scheme = Theme.of(context).colorScheme;
    final r = Responsive.of(context);

    return Scaffold(
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
                        SizedBox(height: r.isLandscape ? 4 : 8),
                        AppLogo(height: r.logoHeight, heroTag: 'app-logo'),
                        SizedBox(height: r.isLandscape ? 8 : 16),
                        Text(
                          _locked
                              ? 'Locked — ${_lockRemaining.inSeconds}s remaining'
                              : 'Enter your PIN',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                        SizedBox(height: r.isLandscape ? 16 : 28),
                        PinDots(length: _pin.length, hasError: _hasError),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 36,
                          child: _error == null
                              ? null
                              : Text(
                                  _error!,
                                  style: TextStyle(color: scheme.error),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                        if (showFingerprint) ...[
                          IconButton.filledTonal(
                            onPressed: _locked || _authenticating
                                ? null
                                : _authenticateBiometric,
                            iconSize: r.shortestSide < 360 ? 28 : 36,
                            icon: _authenticating
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(AppIcons.fingerprint),
                            tooltip: 'Unlock with fingerprint',
                          ),
                          Text(
                            'Use fingerprint',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                PinKeypad(
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                  enabled: !_locked,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
