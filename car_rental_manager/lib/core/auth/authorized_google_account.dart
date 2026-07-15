import '../constants/app_constants.dart';

/// Workshop-owner Google account allowlist helpers.
class AuthorizedGoogleAccount {
  AuthorizedGoogleAccount._();

  static String get email => AppConstants.authorizedGoogleEmail;

  static String get accessDeniedMessage =>
      AppConstants.googleAccessDeniedMessage;

  /// Case-insensitive match against the single authorized email.
  static bool isAuthorized(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    return email.trim().toLowerCase() ==
        AppConstants.authorizedGoogleEmail.toLowerCase();
  }
}
