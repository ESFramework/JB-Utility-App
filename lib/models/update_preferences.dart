class UpdatePreferences {
  final bool autoCheckEnabled;
  final int checkIntervalHours;
  final bool autoDownloadEnabled;
  final DateTime? lastCheckTime;
  final String? lastKnownVersion;
  
  UpdatePreferences({
    this.autoCheckEnabled = true,
    this.checkIntervalHours = 24,
    this.autoDownloadEnabled = false,
    this.lastCheckTime,
    this.lastKnownVersion,
  });
  
  factory UpdatePreferences.fromJson(Map<String, dynamic> json) {
    return UpdatePreferences(
      autoCheckEnabled: json['auto_check_enabled'] ?? true,
      checkIntervalHours: json['check_interval_hours'] ?? 24,
      autoDownloadEnabled: json['auto_download_enabled'] ?? false,
      lastCheckTime: json['last_check_time'] != null 
          ? DateTime.parse(json['last_check_time'])
          : null,
      lastKnownVersion: json['last_known_version'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'auto_check_enabled': autoCheckEnabled,
      'check_interval_hours': checkIntervalHours,
      'auto_download_enabled': autoDownloadEnabled,
      'last_check_time': lastCheckTime?.toIso8601String(),
      'last_known_version': lastKnownVersion,
    };
  }
  
  UpdatePreferences copyWith({
    bool? autoCheckEnabled,
    int? checkIntervalHours,
    bool? autoDownloadEnabled,
    DateTime? lastCheckTime,
    String? lastKnownVersion,
  }) {
    return UpdatePreferences(
      autoCheckEnabled: autoCheckEnabled ?? this.autoCheckEnabled,
      checkIntervalHours: checkIntervalHours ?? this.checkIntervalHours,
      autoDownloadEnabled: autoDownloadEnabled ?? this.autoDownloadEnabled,
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
      lastKnownVersion: lastKnownVersion ?? this.lastKnownVersion,
    );
  }
}