import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/theme_provider.dart';
import '../services/update_provider.dart';
import '../services/update_service.dart';
import 'update_dialogs.dart';

class UpdateCheckerSection extends StatefulWidget {
  const UpdateCheckerSection({super.key});

  @override
  State<UpdateCheckerSection> createState() => _UpdateCheckerSectionState();
}

class _UpdateCheckerSectionState extends State<UpdateCheckerSection> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isTokenConfigured = false;
  
  @override
  void initState() {
    super.initState();
    _loadGitHubToken();
  }
  
  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Consumer<UpdateProvider>(
      builder: (context, updateProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeProvider.secondaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current version info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Version',
                        style: TextStyle(
                          color: themeProvider.textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        updateProvider.updateInfo?.currentVersion ?? '1.0.0',
                        style: TextStyle(
                          color: themeProvider.textColorSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (updateProvider.hasUpdate)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Update Available',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Check for updates button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: updateProvider.isCheckingForUpdates
                      ? null
                      : () => _checkForUpdates(context, updateProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: updateProvider.isCheckingForUpdates
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Checking...',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        )
                      : const Text(
                          'Check for Updates',
                          style: TextStyle(fontSize: 12),
                        ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // GitHub Token Configuration
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                   color: themeProvider.secondaryColor,
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(
                     color: themeProvider.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                     width: 1,
                   ),
                 ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GitHub Configuration',
                      style: TextStyle(
                        color: themeProvider.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your GitHub Personal Access Token to access private repository:',
                      style: TextStyle(
                        color: themeProvider.textColorSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tokenController,
                      obscureText: true,
                      style: TextStyle(
                        color: themeProvider.textColor,
                        fontSize: 11,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                        hintStyle: TextStyle(
                          color: themeProvider.textColorSecondary,
                          fontSize: 11,
                        ),
                        border: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(6),
                           borderSide: BorderSide(
                             color: themeProvider.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                           ),
                         ),
                         enabledBorder: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(6),
                           borderSide: BorderSide(
                             color: themeProvider.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                           ),
                         ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_tokenController.text.isNotEmpty)
                              IconButton(
                                onPressed: _clearGitHubToken,
                                icon: Icon(
                                  Icons.clear,
                                  size: 16,
                                  color: themeProvider.textColorSecondary,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            IconButton(
                              onPressed: _saveGitHubToken,
                              icon: const Icon(
                                Icons.save,
                                size: 16,
                                color: Colors.blue,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isTokenConfigured ? Icons.check_circle : Icons.info_outline,
                          size: 12,
                          color: _isTokenConfigured ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _isTokenConfigured 
                                ? 'GitHub token configured successfully'
                                : 'GitHub token required for private repository access',
                            style: TextStyle(
                              color: _isTokenConfigured ? Colors.green : Colors.orange,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Auto-check toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Auto-check for updates',
                    style: TextStyle(
                      color: themeProvider.textColor,
                      fontSize: 12,
                    ),
                  ),
                  Switch(
                    value: updateProvider.preferences.autoCheckEnabled,
                    onChanged: (value) {
                      updateProvider.toggleAutoCheck(value);
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
              
              // Last check time
              if (updateProvider.preferences.lastCheckTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Last checked: ${_formatDateTime(updateProvider.preferences.lastCheckTime!)}',
                    style: TextStyle(
                      color: themeProvider.textColorSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              
              // Error message
              if (updateProvider.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            updateProvider.error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: updateProvider.clearError,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 16,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _loadGitHubToken() async {
    final updateService = UpdateService();
    final isConfigured = await updateService.isGitHubTokenConfigured();
    if (mounted) {
      setState(() {
        _isTokenConfigured = isConfigured;
      });
    }
  }

  Future<void> _saveGitHubToken() async {
    final token = _tokenController.text.trim();
    if (token.isNotEmpty) {
      final updateService = UpdateService();
      await updateService.saveGitHubToken(token);
      setState(() {
        _isTokenConfigured = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GitHub token saved successfully')),
      );
    }
  }

  Future<void> _clearGitHubToken() async {
    final updateService = UpdateService();
    await updateService.removeGitHubToken();
    setState(() {
      _isTokenConfigured = false;
      _tokenController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GitHub token removed')),
    );
  }
  
  void _checkForUpdates(BuildContext context, UpdateProvider updateProvider) async {
    await updateProvider.checkForUpdates();
    
    if (updateProvider.hasUpdate && context.mounted) {
      UpdateDialogs.showUpdateAvailable(
        context,
        updateProvider.updateInfo!,
        onDownload: () => _downloadUpdate(context, updateProvider),
      );
    } else if (updateProvider.updateInfo != null && context.mounted) {
      UpdateDialogs.showNoUpdatesAvailable(context);
    }
  }
  
  void _downloadUpdate(BuildContext context, UpdateProvider updateProvider) async {
    if (!context.mounted) return;
    
    // Show download progress dialog
    UpdateDialogs.showDownloadProgress(
      context,
      updateProvider,
      onCancel: () {
        // TODO: Implement download cancellation
        Navigator.of(context).pop();
      },
    );
    
    // Start download
    final filePath = await updateProvider.downloadUpdate();
    
    if (filePath != null && context.mounted) {
      Navigator.of(context).pop(); // Close progress dialog
      
      // Verify APK
      final isValid = await updateProvider.verifyApk(filePath);
      
      if (isValid && context.mounted) {
        UpdateDialogs.showInstallReady(
          context,
          filePath,
          onInstall: () => _installUpdate(context, updateProvider, filePath),
        );
      } else if (context.mounted) {
        UpdateDialogs.showVerificationFailed(context);
      }
    } else if (context.mounted) {
      Navigator.of(context).pop(); // Close progress dialog
      UpdateDialogs.showDownloadFailed(context);
    }
  }
  
  void _installUpdate(BuildContext context, UpdateProvider updateProvider, String filePath) async {
    final success = await updateProvider.installApk(filePath);
    
    if (context.mounted) {
      Navigator.of(context).pop(); // Close install dialog
      
      if (success) {
        UpdateDialogs.showInstallationStarted(context);
      } else {
        UpdateDialogs.showInstallationFailed(context);
      }
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }
}