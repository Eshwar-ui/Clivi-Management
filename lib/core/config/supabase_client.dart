import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'env.dart';

/// Global Supabase client instance
final supabase = Supabase.instance.client;

/// Logger for debugging
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 75,
    colors: true,
    printEmojis: true,
  ),
);

enum ConnectionState { connected, paused, disconnected }

/// Initialize Supabase with environment configuration
class SupabaseConfig {
  // Private constructor
  SupabaseConfig._();

  static ConnectionState _connectionState = ConnectionState.connected;

  static ConnectionState get connectionState => _connectionState;

  /// Initialize Supabase
  static Future<void> initialize() async {
    try {
      logger.i('Initializing Supabase...');
      logger.i('Environment: ${Env.appEnv}');

      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
        debug: Env.isDebugMode, // Controlled by .env DEBUG_MODE
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
      );

      // Ensure realtime websocket is up immediately to avoid lazy connect races.
      try {
        // ignore: invalid_use_of_internal_member
        // ignore: invalid_use_of_internal_member
      supabase.realtime.connect();
        logger.i('Realtime socket connected');
      } catch (e) {
        logger.w('Realtime socket connect failed: $e');
      }

      logger.i('Supabase initialized successfully');
    } catch (e, stackTrace) {
      logger.e(
        'Failed to initialize Supabase',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static bool _isRealtimePaused = false;

  static Future<void> handleAppLifecycle(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        // Refresh session and reconnect
        await _refreshConnection();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _connectionState = ConnectionState.paused;
        break;
      case AppLifecycleState.detached:
        // Save any pending data
        await _flushPendingOperations();
        break;
      default:
        break;
    }
  }

  static Future<void> _refreshConnection() async {
    _connectionState = ConnectionState.connected;

    // Ensure realtime socket is connected (idempotent)
    try {
      // ignore: invalid_use_of_internal_member
      supabase.realtime.connect();
      if (_isRealtimePaused) {
        _isRealtimePaused = false;
        logger.i('Realtime connection resumed');
      }
    } catch (e) {
      logger.w('Failed to ensure realtime connection: $e');
    }

    // Refresh session if expiring soon (within 5 minutes)
    final session = supabase.auth.currentSession;
    if (session != null) {
      final expiresAt = session.expiresAt;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (expiresAt != null && expiresAt - now < 300) {
        try {
          await supabase.auth.refreshSession();
          logger.i('Session refreshed on resume');
        } catch (e) {
          logger.e('Session refresh failed: $e');
        }
      }
    }
  }

  // static void _pauseRealtime() {
  //   try {
  //     supabase.realtime.disconnect();
  //     _isRealtimePaused = true;
  //     logger.i('Realtime connection paused');
  //   } catch (e) {
  //     logger.w('Failed to pause realtime: $e');
  //   }
  // }

  static Future<void> _flushPendingOperations() async {
    // TODO: Implement logic to save any pending data before the app is detached.
  }

  /// Check if user is authenticated
  static bool get isAuthenticated => supabase.auth.currentSession != null;

  /// Get current user
  static User? get currentUser => supabase.auth.currentUser;

  /// Get current user ID
  static String? get currentUserId => supabase.auth.currentUser?.id;

  /// Sign out
  static Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
      logger.i('User signed out successfully');
    } catch (e, stackTrace) {
      logger.e('Sign out failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
