import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'update_service.dart';
import 'update_exceptions.dart';

class UpdateProvider extends ChangeNotifier {
  final UpdateService _updateService = UpdateService();
  
  UpdateInfo? _updateInfo;
  DownloadProgress _downloadProgress = DownloadProgress.idle();
  bool _isCheckingForUpdates = false;
  bool _isDownloading = false;
  String? _error;
  UpdatePreferences _preferences = UpdatePreferences();
  
  // Getters
  UpdateInfo? get updateInfo => _updateInfo;
  DownloadProgress get downloadProgress => _downloadProgress;
  bool get isCheckingForUpdates => _isCheckingForUpdates;
  bool get isDownloading => _isDownloading;
  String? get error => _error;
  UpdatePreferences get preferences => _preferences;
  bool get hasUpdate => _updateInfo?.hasUpdate ?? false;
  
  UpdateProvider() {
    _loadPreferences();
    _listenToDownloadProgress();
  }
  
  /// Load user preferences
  Future<void> _loadPreferences() async {
    try {
      _preferences = await _updateService.getUpdatePreferences();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load preferences: $e');
    }
  }
  
  /// Listen to download progress stream
  void _listenToDownloadProgress() {
    _updateService.downloadStream.listen(
      (progress) {
        _downloadProgress = progress;
        _isDownloading = progress.status == DownloadStatus.downloading;
        notifyListeners();
      },
      onError: (error) {
        _setError('Download error: $error');
        _isDownloading = false;
        notifyListeners();
      },
    );
  }
  
  /// Check for updates manually
  Future<void> checkForUpdates() async {
    if (_isCheckingForUpdates) return;
    
    _isCheckingForUpdates = true;
    _error = null;
    notifyListeners();
    
    try {
      _updateInfo = await _updateService.checkForUpdates();
    } catch (e) {
      String errorMessage;
      if (e is NetworkException) {
        errorMessage = e.userMessage.isNotEmpty ? e.userMessage : e.message;
      } else if (e is ParsingException) {
        errorMessage = 'Failed to process update information. Please try again later.';
      } else if (e is UpdateException) {
        errorMessage = e.message;
      } else {
        errorMessage = 'An unexpected error occurred while checking for updates';
      }
      
      _setError(errorMessage);
    } finally {
      _isCheckingForUpdates = false;
      notifyListeners();
    }
  }
  
  /// Download the latest APK
  Future<String?> downloadUpdate() async {
    if (_updateInfo == null || !_updateInfo!.hasUpdate || _isDownloading) {
      return null;
    }
    
    _error = null;
    notifyListeners();
    
    try {
      final fileName = 'app-update-${_updateInfo!.latestVersion}.apk';
      final filePath = await _updateService.downloadApk(
        _updateInfo!.downloadUrl,
        fileName,
      );
      return filePath;
    } catch (e) {
      String errorMessage;
      if (e is NetworkException) {
        errorMessage = e.userMessage.isNotEmpty ? e.userMessage : e.message;
      } else if (e is DownloadException) {
        errorMessage = e.userMessage.isNotEmpty ? e.userMessage : e.message;
      } else if (e is PermissionException) {
        errorMessage = e.userMessage.isNotEmpty ? e.userMessage : e.message;
      } else if (e is StorageException) {
        errorMessage = e.userMessage.isNotEmpty ? e.userMessage : e.message;
      } else if (e is UpdateException) {
        errorMessage = e.message;
      } else {
        errorMessage = 'An unexpected error occurred while downloading the update';
      }
      
      _setError(errorMessage);
      return null;
    }
  }
  
  /// Verify APK signature
  Future<bool> verifyApk(String apkPath) async {
    try {
      return await _updateService.verifyApkSignature(apkPath);
    } catch (e) {
      String errorMessage;
      if (e is VerificationException) {
        errorMessage = e.userMessage.isNotEmpty ? e.userMessage : e.message;
      } else if (e is StorageException) {
        errorMessage = 'Unable to access the downloaded file for verification';
      } else if (e is UpdateException) {
        errorMessage = e.message;
      } else {
        errorMessage = 'An unexpected error occurred while verifying the update';
      }
      
      _setError(errorMessage);
      return false;
    }
  }
  
  /// Install APK
  Future<bool> installApk(String apkPath) async {
    try {
      return await _updateService.installApk(apkPath);
    } catch (e) {
      String errorMessage;
      if (e is InstallationException) {
        errorMessage = e.userMessage.isNotEmpty ? e.userMessage : e.message;
      } else if (e is PermissionException) {
        errorMessage = e.userMessage.isNotEmpty ? e.userMessage : e.message;
      } else if (e is StorageException) {
        errorMessage = 'Unable to access the update file for installation';
      } else if (e is UpdateException) {
        errorMessage = e.message;
      } else {
        errorMessage = 'An unexpected error occurred during installation';
      }
      
      _setError(errorMessage);
      return false;
    }
  }
  
  /// Update preferences
  Future<void> updatePreferences(UpdatePreferences newPreferences) async {
    try {
      await _updateService.saveUpdatePreferences(newPreferences);
      _preferences = newPreferences;
      notifyListeners();
    } catch (e) {
      _setError('Failed to save preferences: $e');
    }
  }
  
  /// Toggle auto-check setting
  Future<void> toggleAutoCheck(bool enabled) async {
    final newPreferences = _preferences.copyWith(autoCheckEnabled: enabled);
    await updatePreferences(newPreferences);
  }
  
  /// Toggle auto-download setting
  Future<void> toggleAutoDownload(bool enabled) async {
    final newPreferences = _preferences.copyWith(autoDownloadEnabled: enabled);
    await updatePreferences(newPreferences);
  }
  
  /// Set check interval
  Future<void> setCheckInterval(int hours) async {
    final newPreferences = _preferences.copyWith(checkIntervalHours: hours);
    await updatePreferences(newPreferences);
  }
  
  /// Check if automatic update check is due
  Future<bool> isUpdateCheckDue() async {
    return await _updateService.isUpdateCheckDue();
  }
  
  /// Perform automatic update check if due
  Future<void> performAutomaticCheck() async {
    if (await isUpdateCheckDue()) {
      await checkForUpdates();
    }
  }
  
  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Set error message
  void _setError(String error) {
    _error = error;
    debugPrint('UpdateProvider Error: $error');
  }
  
  /// Reset update info
  void resetUpdateInfo() {
    _updateInfo = null;
    _downloadProgress = DownloadProgress.idle();
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _updateService.dispose();
    super.dispose();
  }
}