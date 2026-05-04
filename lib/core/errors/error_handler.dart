import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';
import 'app_exceptions.dart';

/// Global error handler for the application
/// Provides consistent error handling and user-friendly messages
class ErrorHandler {
  // Private constructor to prevent instantiation
  ErrorHandler._();

  /// Handle any error and return a user-friendly message
  static String handle(dynamic error, {String? fallbackMessage}) {
    logger.e('Error occurred', error: error);

    // Handle specific exception types
    if (error is AppException) {
      return error.message;
    }

    if (error is AuthException) {
      return _handleAuthError(error);
    }

    if (error is PostgrestException) {
      return _handleDatabaseError(error);
    }

    if (error is StorageException) {
      return _handleStorageError(error);
    }

    if (error is SocketException) {
      return 'No internet connection. Please check your network.';
    }

    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }

    if (error is FormatException) {
      return 'Invalid data format received.';
    }

    if (error is TypeError) {
      return 'Data processing error occurred.';
    }

    // Return fallback or generic message
    return fallbackMessage ?? 'An unexpected error occurred. Please try again.';
  }

  /// Handle authentication errors
  static String _handleAuthError(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid email or password')) {
      return 'Invalid email or password. Please try again.';
    }

    if (message.contains('email not confirmed')) {
      return 'Please verify your email address before logging in.';
    }

    if (message.contains('user already registered') ||
        message.contains('email already exists')) {
      return 'This email is already registered. Please login instead.';
    }

    if (message.contains('weak password')) {
      return 'Password is too weak. Please use a stronger password.';
    }

    if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    if (message.contains('session expired') ||
        message.contains('refresh token')) {
      return 'Your session has expired. Please login again.';
    }

    if (message.contains('too many requests') ||
        message.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }

    if (message.contains('user not found')) {
      return 'No account found with this email address.';
    }

    if (message.contains('signups not allowed')) {
      return 'Registration is currently disabled.';
    }

    return error.message;
  }

  /// Handle database errors
  static String _handleDatabaseError(PostgrestException error) {
    final code = error.code;
    final message = error.message.toLowerCase();

    // Handle specific PostgreSQL error codes
    switch (code) {
      case '23505': // unique_violation
        if (message.contains('email')) {
          return 'This email is already in use.';
        }
        return 'This record already exists.';

      case '23503': // foreign_key_violation
        return 'Cannot complete this action due to related records.';

      case '23502': // not_null_violation
        return 'Required information is missing.';

      case '42501': // insufficient_privilege
        return 'You do not have permission to perform this action.';

      case '42P01': // undefined_table
        return 'Database configuration error. Please contact support.';

      case 'PGRST301': // Row not found
        return 'The requested record was not found.';

      case 'PGRST116': // Multiple rows returned
        return 'Data integrity error. Please contact support.';

      default:
        if (message.contains('permission denied') ||
            message.contains('rls') ||
            message.contains('policy')) {
          return 'You do not have permission to perform this action.';
        }

        if (message.contains('connection') || message.contains('timeout')) {
          return 'Database connection failed. Please try again.';
        }

        return 'Database operation failed. Please try again.';
    }
  }

  /// Handle storage errors
  static String _handleStorageError(StorageException error) {
    final message = error.message.toLowerCase();

    if (message.contains('not found') || message.contains('does not exist')) {
      return 'The requested file was not found.';
    }

    if (message.contains('permission') || message.contains('unauthorized')) {
      return 'You do not have permission to access this file.';
    }

    if (message.contains('too large') || message.contains('size limit')) {
      return 'File is too large. Maximum size is 10MB.';
    }

    if (message.contains('invalid') && message.contains('type')) {
      return 'Invalid file type. Please upload a supported file format.';
    }

    if (message.contains('quota') || message.contains('limit exceeded')) {
      return 'Storage limit exceeded. Please contact support.';
    }

    return 'File operation failed. Please try again.';
  }

  /// Convert any error to AppException
  static AppException toAppException(dynamic error) {
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

    if (error is SocketException) {
      return NetworkException('No internet connection');
    }

    if (error is TimeoutException) {
      return TimeoutException('Request timed out');
    }

    return UnknownException(
      'An unexpected error occurred',
      originalError: error,
    );
  }

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = handle(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show warning snackbar
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show info snackbar
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
  }) async {
    final message = handle(error);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title ?? 'Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Log error for debugging
  static void logError(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    logger.e(context ?? 'Error', error: error, stackTrace: stackTrace);
  }

  /// Check if error is a network error
  static bool isNetworkError(dynamic error) {
    if (error is SocketException) return true;
    if (error is NetworkException) return true;
    if (error is TimeoutException) return true;

    final message = error.toString().toLowerCase();
    return message.contains('network') ||
        message.contains('connection') ||
        message.contains('internet') ||
        message.contains('socket');
  }

  /// Check if error is an authentication error
  static bool isAuthError(dynamic error) {
    if (error is AuthException) return true;
    if (error is AppAuthException) return true;

    final message = error.toString().toLowerCase();
    return message.contains('unauthorized') ||
        message.contains('unauthenticated') ||
        message.contains('session') ||
        message.contains('token');
  }

  /// Check if error is a permission error
  static bool isPermissionError(dynamic error) {
    if (error is PermissionException) return true;

    final message = error.toString().toLowerCase();
    return message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('access denied') ||
        message.contains('not allowed');
  }
}

/// Extension to easily handle errors in async functions
extension ErrorHandlerExtension<T> on Future<T> {
  /// Handle errors and return null on failure
  Future<T?> handleErrors({String? fallbackMessage}) async {
    try {
      return await this;
    } catch (e) {
      logger.e(ErrorHandler.handle(e, fallbackMessage: fallbackMessage));
      return null;
    }
  }

  /// Handle errors with callback
  Future<T?> onError(void Function(dynamic error) callback) async {
    try {
      return await this;
    } catch (e) {
      callback(e);
      return null;
    }
  }
}
