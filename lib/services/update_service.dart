import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'update_exceptions.dart';

class UpdateService {
  static const String _githubApiUrl = 'https://api.github.com/repos';
  static const String _prefsKey = 'update_preferences';
  static const String _githubTokenKey = 'github_token';
  
  // Private repository configuration
  static const String _repoOwner = 'ESFramework';
  static const String _repoName = 'JB-Utility-App';
  
  final Dio _dio = Dio();
  final StreamController<DownloadProgress> _downloadController = StreamController<DownloadProgress>.broadcast();
  
  Stream<DownloadProgress> get downloadStream => _downloadController.stream;
  
  /// Check for available updates
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // Get GitHub token for private repository access
      final token = await _getGitHubToken();
      if (token == null || token.isEmpty) {
        throw const AuthenticationException(
          'GitHub token not configured',
          'Please configure your GitHub personal access token in settings to check for updates',
        );
      }
      
      final response = await http.get(
        Uri.parse('$_githubApiUrl/$_repoOwner/$_repoName/releases/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'JB-Calculator-App',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Request timed out', const Duration(seconds: 30)),
      );
      
      if (response.statusCode == 200) {
        try {
          final release = GitHubRelease.fromJson(json.decode(response.body));
          final latestVersion = _cleanVersion(release.tagName);
          final hasUpdate = _isNewerVersion(currentVersion, latestVersion);
          
          if (hasUpdate) {
            final apkAsset = release.apkAsset;
            if (apkAsset != null) {
              final updateInfo = UpdateInfo(
                currentVersion: currentVersion,
                latestVersion: latestVersion,
                hasUpdate: true,
                downloadUrl: apkAsset.downloadUrl,
                changelog: release.body,
                fileSize: apkAsset.size,
                lastChecked: DateTime.now(),
              );
              
              await _updateLastCheckTime();
              return updateInfo;
            } else {
              throw const ParsingException('No APK file found in the latest release');
            }
          }
          
          await _updateLastCheckTime();
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            hasUpdate: false,
            downloadUrl: '',
            changelog: '',
            fileSize: 0,
            lastChecked: DateTime.now(),
          );
        } catch (e) {
          if (e is UpdateException) rethrow;
          throw ParsingException('Failed to parse release information', e.toString());
        }
      } else if (response.statusCode == 404) {
        throw const NetworkException('Repository not found or no releases available. Please verify your GitHub token has access to the private repository.');
      } else if (response.statusCode == 401) {
        throw const AuthenticationException(
          'GitHub authentication failed',
          'Your GitHub token is invalid or expired. Please update it in settings.',
        );
      } else if (response.statusCode == 403) {
        throw const AuthenticationException(
          'Access forbidden',
          'Your GitHub token does not have permission to access this repository.',
        );
      } else if (response.statusCode >= 500) {
        throw NetworkException('Server error (${response.statusCode})', 'Please try again later');
      } else {
        throw NetworkException('Failed to fetch release info (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      throw UpdateExceptionHandler.handleException(e);
    }
  }
  
  /// Download APK file
  Future<String> downloadApk(String url, String fileName) async {
    try {
      // Get GitHub token for authenticated download
      final token = await _getGitHubToken();
      if (token == null || token.isEmpty) {
        throw const AuthenticationException(
          'GitHub token not configured',
          'Please configure your GitHub personal access token in settings to download updates',
        );
      }
      
      // Request storage permission
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        throw const PermissionException(
          'Storage permission is required to download updates',
          'Please grant storage permission in app settings',
        );
      }
      
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw const StorageException(
          'Could not access external storage',
          'External storage is not available on this device',
        );
      }
      
      final downloadsDir = Directory('${directory.path}/Downloads');
      try {
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
      } catch (e) {
        throw StorageException(
          'Failed to create downloads directory',
          e.toString(),
        );
      }
      
      final filePath = '${downloadsDir.path}/$fileName';
      
      // Delete existing file if it exists
      final file = File(filePath);
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        throw StorageException(
          'Failed to delete existing file',
          e.toString(),
        );
      }
      
      _downloadController.add(DownloadProgress.idle());
      
      try {
        await _dio.download(
          url,
          filePath,
          options: Options(
            receiveTimeout: const Duration(minutes: 10),
            sendTimeout: const Duration(seconds: 30),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/octet-stream',
            },
          ),
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = DownloadProgress.downloading(
                downloaded: received,
                total: total,
                speed: 0.0, // Speed calculation would require time tracking
              );
              _downloadController.add(progress);
            }
          },
        );
        
        // Verify file was downloaded successfully
        if (!await file.exists()) {
          throw const DownloadException('Download completed but file not found');
        }
        
        final fileSize = await file.length();
        if (fileSize == 0) {
          throw const DownloadException('Downloaded file is empty');
        }
        
        _downloadController.add(DownloadProgress.completed(fileSize));
        return filePath;
      } on DioException catch (e) {
        _downloadController.add(DownloadProgress.failed());
        
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            throw const NetworkException(
              'Download timed out',
              'Please check your internet connection and try again',
            );
          case DioExceptionType.connectionError:
            throw const NetworkException(
              'Connection failed',
              'Unable to connect to download server',
            );
          case DioExceptionType.badResponse:
            throw NetworkException(
              'Server error during download',
              'HTTP ${e.response?.statusCode}',
            );
          case DioExceptionType.cancel:
            throw const DownloadException('Download was cancelled');
          default:
            throw DownloadException(
              'Download failed',
              e.message,
            );
        }
      }
    } catch (e) {
      _downloadController.add(DownloadProgress.failed());
      debugPrint('Error downloading APK: $e');
      if (e is UpdateException) rethrow;
      throw UpdateExceptionHandler.handleException(e);
    }
  }
  
  /// Verify APK signature (basic implementation)
  Future<bool> verifyApkSignature(String apkPath) async {
    try {
      final file = File(apkPath);
      if (!await file.exists()) {
        throw const VerificationException(
          'APK file not found',
          'The downloaded file does not exist',
        );
      }
      
      // Basic file integrity check
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw const VerificationException(
          'APK file is empty',
          'The downloaded file contains no data',
        );
      }
      
      // Check if it's a valid APK file (ZIP format)
      if (bytes.length < 4) {
        throw const VerificationException(
          'Invalid APK file',
          'File is too small to be a valid APK',
        );
      }
      
      // ZIP file signature: PK (0x504B)
      if (bytes[0] != 0x50 || bytes[1] != 0x4B) {
        throw const VerificationException(
          'Invalid APK format',
          'File does not have a valid APK signature',
        );
      }
      
      // Check for minimum APK structure
      final bytesString = String.fromCharCodes(bytes.take(1000));
      if (!bytesString.contains('AndroidManifest.xml')) {
        throw const VerificationException(
          'Invalid APK structure',
          'File does not contain required Android manifest',
        );
      }
      
      // Additional checks could be added here for more robust verification
      // For production, you might want to verify against a known certificate
      
      return true;
    } catch (e) {
      debugPrint('Error verifying APK signature: $e');
      if (e is UpdateException) rethrow;
      throw UpdateExceptionHandler.handleException(e);
    }
  }
  
  /// Install APK (opens system installer)
  Future<bool> installApk(String apkPath) async {
    try {
      // Verify file exists before attempting installation
      final file = File(apkPath);
      if (!await file.exists()) {
        throw const InstallationException(
          'APK file not found',
          'The file to install does not exist',
        );
      }
      
      // Request install permission
      final permission = await Permission.requestInstallPackages.request();
      if (!permission.isGranted) {
        throw const PermissionException(
          'Installation permission required',
          'Please allow installation from unknown sources in settings',
        );
      }
      
      // Verify file is readable
      try {
        await file.readAsBytes();
      } catch (e) {
        throw StorageException(
          'Cannot read APK file',
          e.toString(),
        );
      }
      
      // On Android, we need to use platform channels or external packages
      // For now, this is a placeholder that would need platform-specific implementation
      debugPrint('Installing APK: $apkPath');
      
      // In a real implementation, you would use:
      // - Android Intent to open the APK file
      // - Platform channels to communicate with native Android code
      // - External packages like 'install_plugin' or 'open_file'
      
      // Simulate installation process
      await Future.delayed(const Duration(seconds: 1));
      
      return true;
    } catch (e) {
      debugPrint('Error installing APK: $e');
      if (e is UpdateException) rethrow;
      throw UpdateExceptionHandler.handleException(e);
    }
  }
  
  /// Get update preferences
  Future<UpdatePreferences> getUpdatePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      
      if (jsonString != null) {
        final json = jsonDecode(jsonString);
        return UpdatePreferences.fromJson(json);
      }
      
      return UpdatePreferences();
    } catch (e) {
      debugPrint('Error getting update preferences: $e');
      return UpdatePreferences();
    }
  }
  
  /// Save update preferences
  Future<void> saveUpdatePreferences(UpdatePreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(preferences.toJson());
      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      debugPrint('Error saving update preferences: $e');
    }
  }
  
  /// Check if automatic update check is due
  Future<bool> isUpdateCheckDue() async {
    final preferences = await getUpdatePreferences();
    
    if (!preferences.autoCheckEnabled) {
      return false;
    }
    
    if (preferences.lastCheckTime == null) {
      return true;
    }
    
    final now = DateTime.now();
    final timeSinceLastCheck = now.difference(preferences.lastCheckTime!);
    final intervalDuration = Duration(hours: preferences.checkIntervalHours);
    
    return timeSinceLastCheck >= intervalDuration;
  }
  
  /// Clean version string (remove 'v' prefix if present)
  String _cleanVersion(String version) {
    return version.startsWith('v') ? version.substring(1) : version;
  }
  
  /// Compare version strings to determine if newer version is available
  bool _isNewerVersion(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();
    
    // Pad shorter version with zeros
    while (currentParts.length < latestParts.length) {
      currentParts.add(0);
    }
    while (latestParts.length < currentParts.length) {
      latestParts.add(0);
    }
    
    for (int i = 0; i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) {
        return true;
      } else if (latestParts[i] < currentParts[i]) {
        return false;
      }
    }
    
    return false;
  }
  
  /// Update last check time in preferences
  Future<void> _updateLastCheckTime() async {
    final preferences = await getUpdatePreferences();
    final updatedPreferences = preferences.copyWith(
      lastCheckTime: DateTime.now(),
    );
    await saveUpdatePreferences(updatedPreferences);
  }
  
  /// Get GitHub personal access token
  Future<String?> _getGitHubToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_githubTokenKey);
    } catch (e) {
      debugPrint('Error getting GitHub token: $e');
      return null;
    }
  }
  
  /// Save GitHub personal access token
  Future<void> saveGitHubToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_githubTokenKey, token);
    } catch (e) {
      debugPrint('Error saving GitHub token: $e');
      throw StorageException(
        'Failed to save GitHub token',
        e.toString(),
      );
    }
  }
  
  /// Remove GitHub personal access token
  Future<void> removeGitHubToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_githubTokenKey);
    } catch (e) {
      debugPrint('Error removing GitHub token: $e');
    }
  }
  
  /// Check if GitHub token is configured
  Future<bool> isGitHubTokenConfigured() async {
    final token = await _getGitHubToken();
    return token != null && token.isNotEmpty;
  }
  
  /// Dispose resources
  void dispose() {
    _downloadController.close();
    _dio.close();
  }
}