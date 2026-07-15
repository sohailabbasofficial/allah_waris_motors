import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Result of a PIN verification attempt.
class PinVerifyResult {
  const PinVerifyResult({
    required this.success,
    this.isLocked = false,
    this.lockRemaining = Duration.zero,
    this.attemptsRemaining,
    this.errorMessage,
  });

  final bool success;
  final bool isLocked;
  final Duration lockRemaining;
  final int? attemptsRemaining;
  final String? errorMessage;
}

/// Handles hashing, storage, verification, and lockout for the app PIN.
class PinService {
  PinService(this._prefs);

  final SharedPreferences _prefs;

  /// Whether a PIN has been created.
  bool get hasPin {
    final hash = _prefs.getString(AppConstants.keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  /// SHA-256 hash of [pin] with app pepper (never store raw PIN).
  String hashPin(String pin) {
    final bytes = utf8.encode('$pin${AppConstants.pinHashPepper}');
    return sha256.convert(bytes).toString();
  }

  /// Saves a new PIN (store hash only).
  Future<void> savePin(String pin) async {
    await _prefs.setString(AppConstants.keyPinHash, hashPin(pin));
    await _clearLockout();
  }

  /// Returns true if [pin] matches the stored hash.
  bool matches(String pin) {
    final stored = _prefs.getString(AppConstants.keyPinHash);
    if (stored == null) return false;
    return stored == hashPin(pin);
  }

  /// Remaining lockout duration, or [Duration.zero] if not locked.
  Duration lockRemaining() {
    final until = _prefs.getInt(AppConstants.keyPinLockUntil) ?? 0;
    final remaining = until - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) return Duration.zero;
    return Duration(milliseconds: remaining);
  }

  bool get isLocked => lockRemaining() > Duration.zero;

  int get failedAttempts =>
      _prefs.getInt(AppConstants.keyFailedPinAttempts) ?? 0;

  /// Verifies [pin], updating failed-attempt / lockout state.
  Future<PinVerifyResult> verifyPin(String pin) async {
    final remainingLock = lockRemaining();
    if (remainingLock > Duration.zero) {
      return PinVerifyResult(
        success: false,
        isLocked: true,
        lockRemaining: remainingLock,
        errorMessage:
            'Too many attempts. Try again in ${remainingLock.inSeconds}s.',
      );
    }

    // Clear expired lockout counter marker if needed.
    if ((_prefs.getInt(AppConstants.keyPinLockUntil) ?? 0) > 0 &&
        remainingLock == Duration.zero) {
      await _prefs.remove(AppConstants.keyPinLockUntil);
    }

    if (matches(pin)) {
      await _clearLockout();
      return const PinVerifyResult(success: true);
    }

    final attempts = failedAttempts + 1;
    await _prefs.setInt(AppConstants.keyFailedPinAttempts, attempts);

    if (attempts >= AppConstants.maxPinAttempts) {
      final until = DateTime.now()
          .add(AppConstants.pinLockoutDuration)
          .millisecondsSinceEpoch;
      await _prefs.setInt(AppConstants.keyPinLockUntil, until);
      await _prefs.setInt(AppConstants.keyFailedPinAttempts, 0);
      return PinVerifyResult(
        success: false,
        isLocked: true,
        lockRemaining: AppConstants.pinLockoutDuration,
        attemptsRemaining: 0,
        errorMessage:
            'Too many incorrect attempts. Locked for ${AppConstants.pinLockoutDuration.inSeconds} seconds.',
      );
    }

    final left = AppConstants.maxPinAttempts - attempts;
    return PinVerifyResult(
      success: false,
      attemptsRemaining: left,
      errorMessage: 'Incorrect PIN. $left attempt${left == 1 ? '' : 's'} left.',
    );
  }

  /// Removes stored PIN and related security state.
  Future<void> resetPin() async {
    await _prefs.remove(AppConstants.keyPinHash);
    await _clearLockout();
  }

  Future<void> _clearLockout() async {
    await _prefs.setInt(AppConstants.keyFailedPinAttempts, 0);
    await _prefs.remove(AppConstants.keyPinLockUntil);
  }
}