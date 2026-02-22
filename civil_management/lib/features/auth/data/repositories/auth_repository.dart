import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/utils/retry_helper.dart';
import '../models/models.dart';


/// Repository for all authentication-related Supabase operations
/// Follows the Repository Pattern - all Supabase calls go through here
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({SupabaseClient? client}) : _client = client ?? supabase;

  // ============================================================
  // AUTH OPERATIONS
  // ============================================================

  /// Sign in with email and password
  Future<AuthResultModel> signIn(SignInRequest request) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: request.email,
        password: request.password,
      );

      if (response.user == null) {
        return AuthResultModel.failure('Sign in failed');
      }

      // Fetch user profile
      final profile = await getUserProfile(response.user!.id);

      logger.i('User signed in: ${response.user!.email}');

      return AuthResultModel.success(
        user: response.user!,
        session: response.session,
        profile: profile,
      );
    } on AuthException catch (e) {
      logger.e('Sign in failed: ${e.message}');
      throw AppAuthException.fromSupabase(e);
    } catch (e) {
      logger.e('Sign in error: $e');
      throw AppAuthException('An unexpected error occurred during sign in');
    }
  }

  /// Sign up with email and password
  Future<AuthResultModel> signUp(SignUpRequest request) async {
    try {
      // Sign up with user metadata (trigger will create profile automatically)
      final response = await _client.auth.signUp(
        email: request.email,
        password: request.password,
        data: {'full_name': request.fullName, 'phone': request.phone},
      );

      if (response.user == null) {
        return AuthResultModel.failure('Sign up failed');
      }

      logger.i('User signed up: ${response.user!.email}');

      // Use RetryHelper with exponential backoff to wait for trigger-created profile
      final userId = response.user!.id;

      final profile = await RetryHelper.retryUntil<UserProfileModel>(
        () => getUserProfile(userId),
        (result) => result != null,
        maxAttempts: 5,
        initialDelay: const Duration(milliseconds: 100),
        maxDelay: const Duration(seconds: 2),
      );

      // Update profile with additional info if provided and profile exists
      UserProfileModel? finalProfile = profile;
      if (profile != null &&
          (request.fullName != null || request.phone != null)) {
        final updates = <String, dynamic>{};
        if (request.fullName != null) updates['full_name'] = request.fullName;
        if (request.phone != null) updates['phone'] = request.phone;

        if (updates.isNotEmpty) {
          try {
            finalProfile = await updateUserProfile(
              userId: userId,
              updates: updates,
            );
          } catch (e) {
            logger.w('Could not update profile with additional info: $e');
            // Continue with original profile
          }
        }
      }

      return AuthResultModel.success(
        user: response.user!,
        session: response.session,
        profile: finalProfile,
      );
    } on AuthException catch (e) {
      logger.e('Sign up failed: ${e.message}');
      throw AppAuthException.fromSupabase(e);
    } catch (e) {
      logger.e('Sign up error: $e');
      throw AppAuthException('An unexpected error occurred during sign up');
    }
  }

  /// Create a new user as admin without affecting the current session.
  /// Uses the create-site-manager Edge Function with service_role key,
  /// so the admin's session is NEVER touched.
  Future<UserProfileModel> createUserAsAdmin({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? position,
    String? address,
    String role = 'site_manager',
  }) async {
    final adminSession = currentSession;
    if (adminSession == null) {
      throw AppAuthException('Admin must be logged in to create users');
    }

    try {
      final fullName = [firstName, lastName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');

      // Call Edge Function — uses service_role on the server, no client auth change
      final response = await _client.functions.invoke(
        'create-site-manager',
        body: {
          'email': email,
          'password': password,
          'full_name': fullName.isNotEmpty ? fullName : null,
          'phone': phone,
          'position': position,
          'address': address,
          'role': role,
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        final msg = errorData is Map ? errorData['error'] ?? 'Failed to create user' : 'Failed to create user';
        throw AppAuthException(msg.toString());
      }

      final data = response.data;
      if (data == null || data['user'] == null) {
        throw AppAuthException('No user data returned');
      }

      logger.i('Site manager created via Edge Function: $email');
      return UserProfileModel.fromJson(data['user'] as Map<String, dynamic>);
    } on AppAuthException {
      rethrow;
    } catch (e) {
      logger.e('Create user error: $e');
      throw AppAuthException('An unexpected error occurred while creating user');
    }
  }

  /// Delete a user (admin only)
  Future<void> deleteUser(String userId) async {
    try {
      // Typically, deleting a user from 'user_profiles' might be enough to
      // soft-delete them from queries, or you can call a custom RPC
      // if you need to delete them from auth.users.
      // The previous implementation tried to set role to 'deleted', which violates
      // the 'profiles_role_check' constraint. To fully delete a user profile, we
      // issue a delete command.
      await _client.from('user_profiles').delete().eq('id', userId);

      logger.i('User marked as deleted: $userId');
    } on PostgrestException catch (e) {
      logger.e('Failed to delete user profile: ${e.message}');
      throw AppAuthException('Failed to delete user: ${e.message}');
    } catch (e) {
      logger.e('Delete user error: $e');
      throw AppAuthException(
        'An unexpected error occurred while deleting user',
      );
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      logger.i('User signed out');
    } catch (e) {
      logger.e('Sign out error: $e');
      throw AppAuthException('Failed to sign out');
    }
  }

  /// Send password reset email
  Future<void> resetPassword(PasswordResetRequest request) async {
    try {
      await _client.auth.resetPasswordForEmail(request.email);
      logger.i('Password reset email sent to: ${request.email}');
    } on AuthException catch (e) {
      logger.e('Password reset failed: ${e.message}');
      throw AppAuthException.fromSupabase(e);
    }
  }

  /// Update user password
  Future<void> updatePassword(PasswordUpdateRequest request) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: request.newPassword),
      );
      logger.i('Password updated successfully');
    } on AuthException catch (e) {
      logger.e('Password update failed: ${e.message}');
      throw AppAuthException.fromSupabase(e);
    }
  }

  /// Refresh current session
  Future<Session?> refreshSession() async {
    try {
      final response = await _client.auth.refreshSession();
      logger.i('Session refreshed');
      return response.session;
    } catch (e) {
      logger.e('Session refresh failed: $e');
      return null;
    }
  }

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentSession != null;

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ============================================================
  // PROFILE OPERATIONS
  // ============================================================

  /// Get user profile by ID
  Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        logger.w('User profile not found for: $userId');
        return null;
      }

      return UserProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch user profile: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Create user profile
  Future<UserProfileModel> createUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _client
          .from('user_profiles')
          .insert(profileData)
          .select()
          .single();

      logger.i('User profile created');
      return UserProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('Failed to create user profile: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Update user profile
  Future<UserProfileModel> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await _client
          .from('user_profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      logger.i('User profile updated');
      return UserProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('Failed to update user profile: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Update user role (admin only)
  Future<void> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      await _client
          .from('user_profiles')
          .update({
            'role': newRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      logger.i('User role updated to: $newRole');
    } on PostgrestException catch (e) {
      logger.e('Failed to update user role: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Get all users (admin only)
  Future<List<UserProfileModel>> getAllUsers() async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserProfileModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch users: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Get users by role
  Future<List<UserProfileModel>> getUsersByRole(String role) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('role', role)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserProfileModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch users by role: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }
}
