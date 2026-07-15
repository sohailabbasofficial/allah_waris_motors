import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../modules/backup/providers/backup_provider.dart';

/// Whether the workshop owner's Google account is signed in.
final authorizedGoogleSessionProvider = FutureProvider<bool>((ref) async {
  return ref.watch(backupRepositoryProvider).isAuthorizedSession();
});
