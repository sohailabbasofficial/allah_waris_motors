import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';

/// Emits when the splash delay finishes and the app should open home.
///
/// Created when the splash screen is first built; completes after
/// [AppConstants.splashDuration].
final splashNavigationProvider = FutureProvider.autoDispose<void>((ref) async {
  await Future<void>.delayed(AppConstants.splashDuration);
});