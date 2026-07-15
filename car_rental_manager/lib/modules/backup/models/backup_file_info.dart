/// A remote backup file listed from Google Drive.
class BackupFileInfo {
  const BackupFileInfo({
    required this.id,
    required this.name,
    required this.modifiedTime,
    required this.sizeBytes,
    this.md5Checksum,
  });

  final String id;
  final String name;
  final DateTime modifiedTime;
  final int sizeBytes;
  final String? md5Checksum;

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
