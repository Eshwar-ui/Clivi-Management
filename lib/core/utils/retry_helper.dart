import 'dart:async';
import 'dart:math';
import '../config/supabase_client.dart';

/// Retry utility with exponential backoff for transient failures
class RetryHelper {
  /// Execute operation with automatic retry on transient failures
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    Duration maxDelay = const Duration(seconds: 10),
    bool Function(Exception)? retryIf,
  }) async {
    int attempt = 0;

    while (true) {
      try {
        attempt++;
        return await operation();
      } on Exception catch (e) {
        final shouldRetry = retryIf?.call(e) ?? _isRetryable(e);

        if (attempt >= maxAttempts || !shouldRetry) {
          logger.w('Retry exhausted after $attempt attempts: $e');
          rethrow;
        }

        // Exponential backoff with jitter
        final baseDelay = initialDelay * pow(2, attempt - 1);
        final jitter = Duration(milliseconds: Random().nextInt(500));
        final delay = baseDelay + jitter;
        final cappedDelay = delay > maxDelay ? maxDelay : delay;

        logger.i(
          'Retry attempt $attempt/$maxAttempts after ${cappedDelay.inMilliseconds}ms',
        );
        await Future.delayed(cappedDelay);
      }
    }
  }

  /// Retry with a condition check (useful for waiting on async processes)
  ///
  /// [operation] - The async function that returns a result
  /// [condition] - Function to check if result is acceptable
  /// [maxAttempts] - Maximum number of attempts
  ///
  /// Returns the result when condition is met, or null if all attempts fail
  static Future<T?> retryUntil<T>(
    Future<T?> Function() operation,
    bool Function(T?) condition, {
    int maxAttempts = 5,
    Duration initialDelay = const Duration(milliseconds: 100),
    Duration maxDelay = const Duration(seconds: 3),
  }) async {
    int attempt = 0;

    while (attempt < maxAttempts) {
      attempt++;
      try {
        final result = await operation();
        if (condition(result)) {
          logger.d('retryUntil succeeded on attempt $attempt');
          return result;
        }

        if (attempt >= maxAttempts) {
          logger.w('retryUntil condition not met after $maxAttempts attempts');
          return result; // Return last result even if condition not met
        }
      } catch (e) {
        if (attempt >= maxAttempts) {
          logger.e('retryUntil failed after $maxAttempts attempts: $e');
          return null;
        }
      }

      // Exponential backoff
      final delay = Duration(
        milliseconds: min(
          (initialDelay.inMilliseconds * pow(2, attempt - 1)).round(),
          maxDelay.inMilliseconds,
        ),
      );
      logger.d(
        'retryUntil waiting ${delay.inMilliseconds}ms before attempt ${attempt + 1}/$maxAttempts',
      );
      await Future.delayed(delay);
    }

    return null;
  }

  /// Check if exception is retryable (network/timeout issues)
  static bool _isRetryable(Exception e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('timeout') ||
        msg.contains('connection') ||
        msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('503') ||
        msg.contains('502') ||
        msg.contains('429') || // Rate limit
        msg.contains('temporarily') ||
        msg.contains('unavailable');
  }
}
