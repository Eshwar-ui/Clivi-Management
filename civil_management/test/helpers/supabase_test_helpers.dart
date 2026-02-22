import 'package:flutter_test/flutter_test.dart';
import 'package:civil_management/core/config/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'test_helpers.dart';

/// Supabase test helper functions
class SupabaseTestHelper {
  /// Initialize Supabase for testing
  static Future<void> initialize() async {
    // Supabase should already be initialized by the app
    // This is a no-op if already initialized
    try {
      await Supabase.initialize(
        url: const String.fromEnvironment(
          'SUPABASE_URL',
          defaultValue: 'https://fhochkjwsmwuiiqqdupa.supabase.co',
        ),
        anonKey: const String.fromEnvironment(
          'SUPABASE_ANON_KEY',
          defaultValue: 'sb_publishable__KXvv54R30ZgYkABqCL2mA_n-QpAV19',
        ),
      );
    } catch (e) {
      // Already initialized
      print('Supabase already initialized: $e');
    }
  }

  /// Sign in with test credentials
  static Future<User?> signInTestUser() async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: TestConstants.testEmail,
        password: TestConstants.testPassword,
      );
      return response.user;
    } catch (e) {
      print('Failed to sign in test user: $e');
      rethrow;
    }
  }

  /// Sign out current user
  static Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      print('Failed to sign out: $e');
    }
  }

  /// Clean up test projects
  static Future<void> cleanupTestProjects(List<String> projectIds) async {
    if (projectIds.isEmpty) return;

    try {
      for (final projectId in projectIds) {
        try {
          // Use soft delete RPC
          await supabase.rpc(
            'soft_delete_project',
            params: {'p_project_id': projectId},
          );
          print('Cleaned up test project: $projectId');
        } catch (e) {
          print('Failed to cleanup project $projectId: $e');
        }
      }
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    return supabase.auth.currentUser?.id;
  }

  /// Wait for async operation with timeout
  static Future<T> waitFor<T>(
    Future<T> Function() operation, {
    Duration timeout = TestConstants.defaultTimeout,
  }) async {
    return operation().timeout(timeout);
  }
}

/// Custom matchers for Supabase responses
class SupabaseMatchers {
  /// Matcher for valid project ID (UUID format)
  static Matcher isValidProjectId() {
    return matches(
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'),
    );
  }

  /// Matcher for valid timestamp
  static Matcher isValidTimestamp() {
    return isA<DateTime>();
  }
}
