import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/biometric_service.dart';
import '../../../core/services/pin_service.dart';
import '../../../providers/shared_preferences_provider.dart';

final pinServiceProvider = Provider<PinService>((ref) {
  return PinService(ref.watch(sharedPreferencesProvider));
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService(ref.watch(sharedPreferencesProvider));
});

/// Whether a PIN is already stored.
final hasPinProvider = Provider<bool>((ref) {
  return ref.watch(pinServiceProvider).hasPin;
});

/// Device biometric capability (false on web / unsupported hardware).
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.watch(biometricServiceProvider).isAvailable();
});

/// User preference: fingerprint login enabled.
final biometricEnabledProvider =
    NotifierProvider<BiometricEnabledNotifier, bool>(
  BiometricEnabledNotifier.new,
);

class BiometricEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(biometricServiceProvider).isEnabled;
  }

  Future<void> setEnabled(bool value) async {
    await ref.read(biometricServiceProvider).setEnabled(value);
    state = value;
  }
}