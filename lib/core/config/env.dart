import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:clivi_management/core/config/supabase_client.dart' show logger;

/// Environment configuration for the app
/// Loads values from .env file
class Env {
  // Private constructor to prevent instantiation
  Env._();

  /// Initialize environment variables
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: 'assets/env');
      if (kDebugMode) {
        logger.d('ENV: Loaded ${dotenv.env.length} environment variables');
        logger.d('ENV: Keys found: ${dotenv.env.keys.toList()}');
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d('ENV: Failed to load .env file: $e');
      }
      rethrow;
    }
  }

  /// Supabase Project URL
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL not found in .env file');
    }
    return url;
  }

  /// Supabase Anonymous Key
  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in .env file');
    }
    return key;
  }

  /// Debug mode flag - controls Supabase debug logging
  static bool get isDebugMode {
    final debug = dotenv.env['DEBUG_MODE'];
    return debug?.toLowerCase() == 'true';
  }

  /// App environment (development, staging, production)
  static String get appEnv {
    return dotenv.env['APP_ENV'] ?? 'development';
  }

  /// Check if running in production
  static bool get isProduction => appEnv == 'production';

  /// Check if running in development
  static bool get isDevelopment => appEnv == 'development';

  /// Check if all required environment variables are present
  static bool validate() {
    try {
      final url = dotenv.env['SUPABASE_URL'];
      final key = dotenv.env['SUPABASE_ANON_KEY'];

      if (kDebugMode) {
        logger.d(
          'ENV Validate: SUPABASE_URL = ${url != null ? "present (${url.length} chars)" : "MISSING"}',
        );
        logger.d(
          'ENV Validate: SUPABASE_ANON_KEY = ${key != null ? "present (${key.length} chars)" : "MISSING"}',
        );
      }

      if (url == null || url.isEmpty) {
        if (kDebugMode) {
          logger.d('ENV Validate: FAILED - SUPABASE_URL missing or empty');
        }
        return false;
      }
      if (key == null || key.isEmpty) {
        if (kDebugMode) {
          logger.d('ENV Validate: FAILED - SUPABASE_ANON_KEY missing or empty');
        }
        return false;
      }

      if (kDebugMode) logger.d('ENV Validate: SUCCESS');
      return true;
    } catch (e) {
      if (kDebugMode) logger.d('ENV Validate: EXCEPTION - $e');
      return false;
    }
  }
}
