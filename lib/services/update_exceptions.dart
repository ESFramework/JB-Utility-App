import 'dart:io';
import 'dart:async';

/// Custom exceptions for update operations
class UpdateException implements Exception {
  final String message;
  final String? details;
  final UpdateErrorType type;
  
  const UpdateException(this.message, this.type, [this.details]);
  
  @override
  String toString() {
    return details != null ? '$message: $details' : message;
  }
}

enum UpdateErrorType {
  network,
  permission,
  storage,
  download,
  verification,
  installation,
  parsing,
  authentication,
  unknown,
}

/// Network-related exceptions
class NetworkException extends UpdateException {
  const NetworkException(String message, [String? details])
      : super(message, UpdateErrorType.network, details);
  
  String get userMessage => UpdateExceptionHandler.getUserFriendlyMessage(this);
}

/// Permission-related exceptions
class PermissionException extends UpdateException {
  const PermissionException(String message, [String? details])
      : super(message, UpdateErrorType.permission, details);
  
  String get userMessage => getUserFriendlyMessage(this);
  
  static String getUserFriendlyMessage(PermissionException exception) {
    return 'Permission required to proceed. Please grant the necessary permissions.';
  }
}

/// Storage-related exceptions
class StorageException extends UpdateException {
  const StorageException(String message, [String? details])
      : super(message, UpdateErrorType.storage, details);
  
  String get userMessage => UpdateExceptionHandler.getUserFriendlyMessage(this);
}

/// Download-related exceptions
class DownloadException extends UpdateException {
  const DownloadException(String message, [String? details])
      : super(message, UpdateErrorType.download, details);
  
  String get userMessage => UpdateExceptionHandler.getUserFriendlyMessage(this);
}

/// Verification-related exceptions
class VerificationException extends UpdateException {
  const VerificationException(String message, [String? details])
      : super(message, UpdateErrorType.verification, details);
  
  String get userMessage => UpdateExceptionHandler.getUserFriendlyMessage(this);
}

/// Installation-related exceptions
class InstallationException extends UpdateException {
  const InstallationException(String message, [String? details])
      : super(message, UpdateErrorType.installation, details);
  
  String get userMessage => UpdateExceptionHandler.getUserFriendlyMessage(this);
}

/// Parsing-related exceptions
class ParsingException extends UpdateException {
  const ParsingException(String message, [String? details])
      : super(message, UpdateErrorType.parsing, details);
  
  String get userMessage => UpdateExceptionHandler.getUserFriendlyMessage(this);
}

/// Authentication-related exceptions
class AuthenticationException extends UpdateException {
  const AuthenticationException(String message, [String? details])
      : super(message, UpdateErrorType.authentication, details);
  
  String get userMessage => UpdateExceptionHandler.getUserFriendlyMessage(this);
}

/// Helper class to convert common exceptions to UpdateExceptions
class UpdateExceptionHandler {
  static UpdateException handleException(dynamic error) {
    if (error is UpdateException) {
      return error;
    }
    
    if (error is SocketException) {
      return NetworkException(
        'Network connection failed',
        'Please check your internet connection and try again.',
      );
    }
    
    if (error is HttpException) {
      return NetworkException(
        'HTTP request failed',
        error.message,
      );
    }
    
    if (error is TimeoutException) {
      return NetworkException(
        'Request timed out',
        'The server took too long to respond. Please try again.',
      );
    }
    
    if (error is FormatException) {
      return ParsingException(
        'Invalid data format',
        error.message,
      );
    }
    
    if (error is FileSystemException) {
      return StorageException(
        'File system error',
        error.message,
      );
    }
    
    // Generic exception
    return UpdateException(
      'An unexpected error occurred',
      UpdateErrorType.unknown,
      error.toString(),
    );
  }
  
  static String getErrorMessage(UpdateException exception) {
    switch (exception.type) {
      case UpdateErrorType.network:
        return 'Network Error: ${exception.message}';
      case UpdateErrorType.permission:
        return 'Permission Error: ${exception.message}';
      case UpdateErrorType.storage:
        return 'Storage Error: ${exception.message}';
      case UpdateErrorType.download:
        return 'Download Error: ${exception.message}';
      case UpdateErrorType.verification:
        return 'Verification Error: ${exception.message}';
      case UpdateErrorType.installation:
        return 'Installation Error: ${exception.message}';
      case UpdateErrorType.parsing:
        return 'Data Error: ${exception.message}';
      case UpdateErrorType.authentication:
        return 'Authentication Error: ${exception.message}';
      case UpdateErrorType.unknown:
        return 'Unknown Error: ${exception.message}';
    }
  }
  
  static String getUserFriendlyMessage(UpdateException exception) {
    switch (exception.type) {
      case UpdateErrorType.network:
        return 'Unable to connect to the update server. Please check your internet connection.';
      case UpdateErrorType.permission:
        return 'Permission required to proceed. Please grant the necessary permissions.';
      case UpdateErrorType.storage:
        return 'Unable to access device storage. Please ensure sufficient space is available.';
      case UpdateErrorType.download:
        return 'Failed to download the update. Please try again.';
      case UpdateErrorType.verification:
        return 'Update verification failed. The downloaded file may be corrupted.';
      case UpdateErrorType.installation:
        return 'Installation failed. Please ensure you have permission to install apps.';
      case UpdateErrorType.parsing:
        return 'Invalid update information received from server.';
      case UpdateErrorType.authentication:
        return 'GitHub authentication failed. Please check your personal access token in settings.';
      case UpdateErrorType.unknown:
        return 'An unexpected error occurred. Please try again later.';
    }
  }
}