// File: lib/app/core/utils/retry_helper.dart
import 'dart:async';
import 'dart:math';

class RetryHelper {
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    bool Function(Exception)? retryIf,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        if (e is! Exception || attempt >= maxAttempts) {
          rethrow;
        }

        // Check if we should retry this specific exception
        if (retryIf != null && !retryIf(e)) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(delay);

        // Exponential backoff
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }

    throw Exception('Max retry attempts reached');
  }

  // Specific retry for Supabase operations
  static Future<T> retrySupabase<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
  }) {
    return retry<T>(
      operation: operation,
      maxAttempts: maxAttempts,
      retryIf: (e) {
        final message = e.toString().toLowerCase();
        // Retry on network errors or rate limits
        return message.contains('network') ||
            message.contains('timeout') ||
            message.contains('rate limit') ||
            message.contains('connection');
      },
    );
  }
}

// Extension for easy usage with Futures
extension RetryExtension<T> on Future<T> {
  Future<T> withRetry({
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) {
    return RetryHelper.retry(
      operation: () => this,
      maxAttempts: maxAttempts,
      initialDelay: initialDelay,
    );
  }
}
