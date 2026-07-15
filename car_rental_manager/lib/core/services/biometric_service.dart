import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Wraps [LocalAuthentication] and the biometric-enabled preference.
class BiometricService {
  BiometricService(this._prefs, [LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final SharedPreferences _prefs;
  final LocalAuthentication _auth;

  /// Whether the user enabled fingerprint / biometric login in Settings.
  bool get isEnabled =>
      _prefs.getBool(AppConstants.keyBiometricEnabled) ?? false;

  Future<void> setEnabled(bool value) async {
    await _prefs.setBool(AppConstants.keyBiometricEnabled, value);
  }

  /// True when the device can use biometrics (hidden on web / unsupported).
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!canCheck && !supported) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty || supported;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the system biometric dialog. Returns true on success.
  Future<bool> authenticate({
    String reason = 'Authenticate to unlock Allah Waris Motors',
  }) async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}