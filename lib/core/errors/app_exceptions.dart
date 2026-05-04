import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Base exception class for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Authentication related exceptions
class AppAuthException extends AppException {
  AppAuthException(super.message, {super.code, super.originalError});

  factory AppAuthException.fromSupabase(AuthException error) {
    return AppAuthException(
      _getReadableAuthMessage(error.message),
      code: error.statusCode,
      originalError: error,
    );
  }

  static String _getReadableAuthMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Incorrect password, invalid email, or no account registered to this email';
    }
    if (message.contains('Email not confirmed')) {
      return 'Please verify your email address';
    }
    if (message.contains('User already registered')) {
      return 'This email is already registered';
    }
    return message;
  }
}

/// Network related exceptions
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError});
}

/// Database related exceptions
class DatabaseException extends AppException {
  DatabaseException(super.message, {super.code, super.originalError});

  factory DatabaseException.fromPostgrest(PostgrestException error) {
    return DatabaseException(
      _getReadableDatabaseMessage(error.message),
      code: error.code,
      originalError: error,
    );
  }

  static String _getReadableDatabaseMessage(String message) {
    if (message.contains('duplicate key')) {
      return 'This record already exists';
    }
    if (message.contains('foreign key')) {
      return 'Cannot perform this operation due to related records';
    }
    if (message.contains('permission denied')) {
      return 'You do not have permission to perform this action';
    }
    // In debug mode, show actual error for debugging; in release show generic message
    return kDebugMode
        ? 'Database error: $message'
        : 'Database operation failed';
  }
}

/// Storage related exceptions
class AppStorageException extends AppException {
  AppStorageException(super.message, {super.code, super.originalError});

  factory AppStorageException.fromSupabase(StorageException error) {
    return AppStorageException(
      error.message,
      code: error.statusCode,
      originalError: error,
    );
  }
}

/// Specific exception for storage upload errors
class StorageUploadException extends AppStorageException {
  StorageUploadException(super.message, {super.code, super.originalError});

  factory StorageUploadException.fromStorageException(StorageException error) {
    return StorageUploadException(
      'Failed to upload file: ${error.message}',
      code: error.statusCode,
      originalError: error,
    );
  }
}

/// Specific exception for storage delete errors
class StorageDeleteException extends AppStorageException {
  StorageDeleteException(super.message, {super.code, super.originalError});

  factory StorageDeleteException.fromStorageException(StorageException error) {
    return StorageDeleteException(
      'Failed to delete file: ${error.message}',
      code: error.statusCode,
      originalError: error,
    );
  }
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.originalError,
  });
}

/// Permission denied exceptions
class PermissionException extends AppException {
  PermissionException(super.message, {super.code, super.originalError});
}

/// Not found exceptions
class NotFoundException extends AppException {
  NotFoundException(super.message, {super.code, super.originalError});
}

/// Server exceptions
class ServerException extends AppException {
  ServerException(super.message, {super.code, super.originalError});
}

/// Timeout exceptions
class TimeoutException extends AppException {
  TimeoutException(super.message, {super.code, super.originalError});
}

/// Unknown exceptions
class UnknownException extends AppException {
  UnknownException(super.message, {super.code, super.originalError});
}

/// Exception handler utility
class ExceptionHandler {
  /// Convert any exception to AppException
  static AppException handle(dynamic error) {
    if (error is AppException) {
      return error;
    }

    if (error is AuthException) {
      return AppAuthException.fromSupabase(error);
    }

    if (error is PostgrestException) {
      return DatabaseException.fromPostgrest(error);
    }

    if (error is StorageException) {
      return AppStorageException.fromSupabase(error);
    }

    // Handle generic errors
    return UnknownException(
      'An unexpected error occurred',
      originalError: error,
    );
  }

  /// Get user-friendly message from exception
  static String getMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    return 'An unexpected error occurred';
  }
}
