class GitHubAsset {
  final String name;
  final String downloadUrl;
  final int size;
  final String contentType;
  
  GitHubAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
    required this.contentType,
  });
  
  factory GitHubAsset.fromJson(Map<String, dynamic> json) {
    return GitHubAsset(
      name: json['name'],
      downloadUrl: json['browser_download_url'],
      size: json['size'],
      contentType: json['content_type'] ?? 'application/vnd.android.package-archive',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'browser_download_url': downloadUrl,
      'size': size,
      'content_type': contentType,
    };
  }
}

class GitHubRelease {
  final String tagName;
  final String name;
  final String body;
  final DateTime publishedAt;
  final List<GitHubAsset> assets;
  
  GitHubRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.assets,
  });
  
  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    return GitHubRelease(
      tagName: json['tag_name'],
      name: json['name'],
      body: json['body'] ?? '',
      publishedAt: DateTime.parse(json['published_at']),
      assets: (json['assets'] as List)
          .map((asset) => GitHubAsset.fromJson(asset))
          .toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'tag_name': tagName,
      'name': name,
      'body': body,
      'published_at': publishedAt.toIso8601String(),
      'assets': assets.map((asset) => asset.toJson()).toList(),
    };
  }
  
  /// Get the APK asset from the release
  GitHubAsset? get apkAsset {
    return assets.firstWhere(
      (asset) => asset.name.toLowerCase().endsWith('.apk'),
      orElse: () => throw Exception('No APK found in release assets'),
    );
  }
}