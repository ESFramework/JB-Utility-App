class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool hasUpdate;
  final String downloadUrl;
  final String changelog;
  final int fileSize;
  final DateTime lastChecked;
  
  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.hasUpdate,
    required this.downloadUrl,
    required this.changelog,
    required this.fileSize,
    required this.lastChecked,
  });
  
  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      currentVersion: json['current_version'],
      latestVersion: json['latest_version'],
      hasUpdate: json['has_update'],
      downloadUrl: json['download_url'],
      changelog: json['changelog'],
      fileSize: json['file_size'],
      lastChecked: DateTime.parse(json['last_checked']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'current_version': currentVersion,
      'latest_version': latestVersion,
      'has_update': hasUpdate,
      'download_url': downloadUrl,
      'changelog': changelog,
      'file_size': fileSize,
      'last_checked': lastChecked.toIso8601String(),
    };
  }
}