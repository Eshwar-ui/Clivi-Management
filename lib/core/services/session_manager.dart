import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';

/// Service for managing session health and validation
///
/// Provides methods to ensure valid session before API calls
/// and handles automatic token refresh
class SessionManager {
  static SessionManager? _instance;
  static SessionManager get instance => _instance ??= SessionManager._();

  SessionManager._();

  /// Buffer time before token expiry to trigger refresh (5 minutes)
  static const Duration _refreshBuffer = Duration(minutes: 5);

  /// Minimum time between refresh attempts to prevent spam
  static const Duration _minRefreshInterval = Duration(seconds: 30);

  DateTime? _lastRefreshAttempt;
  bool _isRefreshing = false;

  /// Get the current session
  Session? get currentSession => supabase.auth.currentSession;

  /// Check if user is authenticated
  bool get isAuthenticated => currentSession != null;

  /// Check if current session is valid (not expired)
  bool get isSessionValid {
    final session = currentSession;
    if (session == null) return false;

    final expiresAt = session.expiresAt;
    if (expiresAt == null) return true; // Assume valid if no expiry

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    return DateTime.now().isBefore(expiryTime);
  }

  /// Check if session needs refresh (within buffer time of expiry)
  bool get needsRefresh {
    final session = currentSession;
    if (session == null) return false;

    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    final refreshThreshold = expiryTime.subtract(_refreshBuffer);

    return DateTime.now().isAfter(refreshThreshold);
  }

  /// Get time until session expires
  Duration? get timeUntilExpiry {
    final session = currentSession;
    if (session?.expiresAt == null) return null;

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(
      session!.expiresAt! * 1000,
    );
    return expiryTime.difference(DateTime.now());
  }

  /// Ensure session is valid before making API call
  ///
  /// This method should be called before critical API operations.
  /// It will refresh the session if needed or throw if not authenticated.
  ///
  /// Usage:
  /// ```dart
  /// await SessionManager.instance.ensureValidSession();
  /// final data = await supabase.from('table').select();
  /// ```
  Future<void> ensureValidSession() async {
    if (!isAuthenticated) {
      throw AuthException('Not authenticated');
    }

    // Check if session is expired
    if (!isSessionValid) {
      logger.w('Session expired, attempting refresh');
      await refreshSession();
      return;
    }

    // Check if session needs proactive refresh
    if (needsRefresh) {
      logger.d('Session nearing expiry, proactively refreshing');
      // Don't await - do async refresh while allowing request to proceed
      _refreshIfNeeded();
    }
  }

  /// Refresh the current session
  ///
  /// Returns true if refresh was successful, false otherwise
  Future<bool> refreshSession() async {
    if (_isRefreshing) {
      // Wait for ongoing refresh to complete
      await Future.delayed(const Duration(milliseconds: 100));
      return isSessionValid;
    }

    // Rate limit refresh attempts
    if (_lastRefreshAttempt != null) {
      final timeSinceLastRefresh = DateTime.now().difference(
        _lastRefreshAttempt!,
      );
      if (timeSinceLastRefresh < _minRefreshInterval) {
        logger.d('Skipping refresh - too soon since last attempt');
        return isSessionValid;
      }
    }

    _isRefreshing = true;
    _lastRefreshAttempt = DateTime.now();

    try {
      final response = await supabase.auth.refreshSession();
      if (response.session != null) {
        logger.i('Session refreshed successfully');
        return true;
      } else {
        logger.w('Session refresh returned no session');
        return false;
      }
    } on AuthException catch (e) {
      logger.e('Session refresh failed: ${e.message}');
      return false;
    } catch (e) {
      logger.e('Session refresh error: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Proactively refresh session if needed (non-blocking)
  Future<void> _refreshIfNeeded() async {
    if (!needsRefresh || _isRefreshing) return;

    try {
      await refreshSession();
    } catch (e) {
      // Log but don't throw - this is proactive refresh
      logger.w('Proactive session refresh failed: $e');
    }
  }

  /// Validate session and get user ID
  ///
  /// Throws if not authenticated
  String requireUserId() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException('Not authenticated');
    }
    return userId;
  }

  /// Start periodic session health check
  ///
  /// Call this on app startup to ensure session stays fresh
  Timer? _healthCheckTimer;

  void startHealthCheck({Duration interval = const Duration(minutes: 1)}) {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(interval, (_) {
      _refreshIfNeeded();
    });
    logger.d('Session health check started');
  }

  /// Stop periodic health check
  void stopHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    logger.d('Session health check stopped');
  }

  /// Dispose resources
  void dispose() {
    stopHealthCheck();
  }
}
