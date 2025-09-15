enum DownloadStatus {
  idle,
  downloading,
  completed,
  failed,
  cancelled
}

class DownloadProgress {
  final int downloaded;
  final int total;
  final double percentage;
  final double speed;
  final DownloadStatus status;
  
  DownloadProgress({
    required this.downloaded,
    required this.total,
    required this.percentage,
    required this.speed,
    required this.status,
  });
  
  factory DownloadProgress.idle() {
    return DownloadProgress(
      downloaded: 0,
      total: 0,
      percentage: 0.0,
      speed: 0.0,
      status: DownloadStatus.idle,
    );
  }
  
  factory DownloadProgress.downloading({
    required int downloaded,
    required int total,
    required double speed,
  }) {
    final percentage = total > 0 ? (downloaded / total) * 100 : 0.0;
    return DownloadProgress(
      downloaded: downloaded,
      total: total,
      percentage: percentage,
      speed: speed,
      status: DownloadStatus.downloading,
    );
  }
  
  factory DownloadProgress.completed(int total) {
    return DownloadProgress(
      downloaded: total,
      total: total,
      percentage: 100.0,
      speed: 0.0,
      status: DownloadStatus.completed,
    );
  }
  
  factory DownloadProgress.failed() {
    return DownloadProgress(
      downloaded: 0,
      total: 0,
      percentage: 0.0,
      speed: 0.0,
      status: DownloadStatus.failed,
    );
  }
  
  factory DownloadProgress.cancelled() {
    return DownloadProgress(
      downloaded: 0,
      total: 0,
      percentage: 0.0,
      speed: 0.0,
      status: DownloadStatus.cancelled,
    );
  }
}