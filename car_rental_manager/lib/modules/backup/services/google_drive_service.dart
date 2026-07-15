import 'dart:async';
import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

import '../../../core/auth/authorized_google_account.dart';
import '../../../core/constants/app_constants.dart';
import '../models/backup_file_info.dart';

class GoogleAuthException implements Exception {
  GoogleAuthException(this.message);
  final String message;

  @override
  String toString() => message;

  bool get isAccessDenied =>
      message == AuthorizedGoogleAccount.accessDeniedMessage;
}

class GoogleDriveException implements Exception {
  GoogleDriveException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Google Sign-In + Drive.file scoped uploads/downloads.
class GoogleDriveService {
  GoogleDriveService();

  static const scopes = <String>[drive.DriveApi.driveFileScope];

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  bool _initialized = false;
  GoogleSignInAccount? _account;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSub;

  GoogleSignInAccount? get currentAccount => _account;

  Future<void> initialize() async {
    if (_initialized) return;
    await _signIn.initialize(
      clientId: AppConstants.googleSignInClientId,
      serverClientId: AppConstants.googleSignInServerClientId,
    );
    _authSub ??= _signIn.authenticationEvents.listen((event) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn():
          _account = event.user;
          unawaited(_rejectUnauthorizedAccount());
        case GoogleSignInAuthenticationEventSignOut():
          _account = null;
      }
    });
    try {
      final silent = _signIn.attemptLightweightAuthentication();
      if (silent != null) {
        _account = await silent;
        await _rejectUnauthorizedAccount();
      }
    } catch (_) {
      // Silent auth is optional.
    }
    _initialized = true;
  }

  /// Signs out immediately if the signed-in email is not the workshop owner.
  Future<void> _rejectUnauthorizedAccount() async {
    final account = _account;
    if (account == null) return;
    if (AuthorizedGoogleAccount.isAuthorized(account.email)) return;
    await _signIn.signOut();
    _account = null;
  }

  Future<void> _ensureAuthorizedOrThrow(GoogleSignInAccount account) async {
    if (AuthorizedGoogleAccount.isAuthorized(account.email)) return;
    await signOut();
    throw GoogleAuthException(AuthorizedGoogleAccount.accessDeniedMessage);
  }

  Future<GoogleSignInAccount> signIn() async {
    await initialize();
    if (kIsWeb) {
      throw GoogleAuthException(
        'Google Drive backup is not supported on web in this app.',
      );
    }
    try {
      if (!_signIn.supportsAuthenticate()) {
        throw GoogleAuthException(
          'Google Sign-In is not available on this platform.',
        );
      }
      _account = await _signIn.authenticate(scopeHint: scopes);
      await _ensureAuthorizedOrThrow(_account!);
      await _authorizeScopes(interactive: true);
      return _account!;
    } on GoogleAuthException {
      rethrow;
    } on GoogleSignInException catch (e) {
      throw GoogleAuthException(
        e.description ?? 'Google Sign-In failed (${e.code.name}).',
      );
    } catch (e) {
      throw GoogleAuthException('Google Sign-In failed: $e');
    }
  }

  Future<void> signOut() async {
    await initialize();
    await _signIn.signOut();
    _account = null;
  }

  Future<void> disconnect() async {
    await initialize();
    await _signIn.disconnect();
    _account = null;
  }

  Future<auth.AuthClient> _authClient({bool interactive = false}) async {
    await initialize();
    final account = _account;
    if (account == null) {
      throw GoogleAuthException('Please sign in with Google first.');
    }
    await _ensureAuthorizedOrThrow(account);
    final authorization = await _authorizeScopes(interactive: interactive);
    return authorization.authClient(scopes: scopes);
  }

  Future<GoogleSignInClientAuthorization> _authorizeScopes({
    required bool interactive,
  }) async {
    final account = _account;
    if (account == null) {
      throw GoogleAuthException('Please sign in with Google first.');
    }

    var authorization =
        await account.authorizationClient.authorizationForScopes(scopes);
    if (authorization == null && interactive) {
      authorization =
          await account.authorizationClient.authorizeScopes(scopes);
    }
    if (authorization == null) {
      throw GoogleAuthException(
        'Drive permission was not granted. Please allow Google Drive access.',
      );
    }
    return authorization;
  }

  Future<drive.DriveApi> _driveApi({bool interactive = false}) async {
    final client = await _authClient(interactive: interactive);
    return drive.DriveApi(client);
  }

  Future<String> ensureBackupFolder({bool interactive = false}) async {
    final api = await _driveApi(interactive: interactive);
    final existing = await api.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and "
          "name='${AppConstants.driveBackupFolderName}' and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name)',
      pageSize: 1,
    );
    final files = existing.files;
    if (files != null && files.isNotEmpty && files.first.id != null) {
      return files.first.id!;
    }

    final folder = await api.files.create(
      drive.File()
        ..name = AppConstants.driveBackupFolderName
        ..mimeType = 'application/vnd.google-apps.folder',
    );
    final id = folder.id;
    if (id == null) {
      throw GoogleDriveException('Could not create Drive backup folder.');
    }
    return id;
  }

  Future<String?> _findFileId({
    required drive.DriveApi api,
    required String folderId,
    required String name,
  }) async {
    final listed = await api.files.list(
      q: "name='$name' and '$folderId' in parents and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name)',
      pageSize: 10,
    );
    final files = listed.files;
    if (files == null || files.isEmpty) return null;
    return files.first.id;
  }

  Future<BackupFileInfo> uploadBytes({
    required String fileName,
    required List<int> bytes,
    bool interactive = false,
    /// When false, always create a new Drive file (never overwrite history).
    bool overwriteExisting = true,
    void Function(double progress)? onProgress,
  }) async {
    final api = await _driveApi(interactive: interactive);
    final folderId = await ensureBackupFolder(interactive: interactive);
    final existingId = overwriteExisting
        ? await _findFileId(
            api: api,
            folderId: folderId,
            name: fileName,
          )
        : null;

    final media = drive.Media(
      Stream<List<int>>.fromIterable([bytes]),
      bytes.length,
    );

    onProgress?.call(0.2);
    drive.File result;
    if (existingId != null) {
      result = await api.files.update(
        drive.File()..name = fileName,
        existingId,
        uploadMedia: media,
        $fields: 'id,name,modifiedTime,size,md5Checksum',
      );
    } else {
      result = await api.files.create(
        drive.File()
          ..name = fileName
          ..parents = [folderId],
        uploadMedia: media,
        $fields: 'id,name,modifiedTime,size,md5Checksum',
      );
    }
    onProgress?.call(1);

    return BackupFileInfo(
      id: result.id ?? existingId ?? '',
      name: result.name ?? fileName,
      modifiedTime: result.modifiedTime ?? DateTime.now(),
      sizeBytes: int.tryParse(result.size ?? '') ?? bytes.length,
      md5Checksum: result.md5Checksum,
    );
  }

  Future<List<BackupFileInfo>> listBackupFiles({
    bool interactive = false,
  }) async {
    final api = await _driveApi(interactive: interactive);
    final folderId = await ensureBackupFolder(interactive: interactive);
    final listed = await api.files.list(
      q: "'$folderId' in parents and trashed=false",
      spaces: 'drive',
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,modifiedTime,size,md5Checksum)',
      pageSize: 50,
    );

    final files = listed.files ?? const <drive.File>[];
    return files
        .where((f) => f.id != null && f.name != null)
        .map(
          (f) => BackupFileInfo(
            id: f.id!,
            name: f.name!,
            modifiedTime: f.modifiedTime ?? DateTime.now(),
            sizeBytes: int.tryParse(f.size ?? '0') ?? 0,
            md5Checksum: f.md5Checksum,
          ),
        )
        .toList();
  }

  Future<Uint8List> downloadFile(
    String fileId, {
    bool interactive = false,
    void Function(double progress)? onProgress,
  }) async {
    final api = await _driveApi(interactive: interactive);
    onProgress?.call(0.1);
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final builder = BytesBuilder(copy: false);
    var received = 0;
    final total = media.length;
    await for (final chunk in media.stream) {
      builder.add(chunk);
      received += chunk.length;
      if (total != null && total > 0) {
        onProgress?.call((received / total).clamp(0, 1));
      }
    }
    onProgress?.call(1);
    final bytes = builder.takeBytes();
    if (bytes.isEmpty) {
      throw GoogleDriveException('Downloaded backup file is empty.');
    }
    return Uint8List.fromList(bytes);
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    _authSub = null;
  }
}
