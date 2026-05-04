import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'user_profile_model.dart';

/// Result model for authentication operations
class AuthResultModel {
  final supabase.User? user;
  final supabase.Session? session;
  final UserProfileModel? profile;
  final String? error;

  const AuthResultModel({this.user, this.session, this.profile, this.error});

  bool get isSuccess => user != null && error == null;
  bool get hasSession => session != null;
  bool get hasProfile => profile != null;

  factory AuthResultModel.success({
    required supabase.User user,
    supabase.Session? session,
    UserProfileModel? profile,
  }) {
    return AuthResultModel(user: user, session: session, profile: profile);
  }

  factory AuthResultModel.failure(String error) {
    return AuthResultModel(error: error);
  }

  @override
  String toString() {
    return 'AuthResultModel(user: ${user?.email}, hasSession: $hasSession, hasProfile: $hasProfile, error: $error)';
  }
}

/// Model for sign up request
class SignUpRequest {
  final String email;
  final String password;
  final String? fullName;
  final String? phone;

  const SignUpRequest({
    required this.email,
    required this.password,
    this.fullName,
    this.phone,
  });

  Map<String, dynamic> toProfileJson(String userId) {
    return {
      'id': userId,
      'role': 'site_manager', // Default role for new users
      'full_name': fullName,
      'phone': phone,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}

/// Model for sign in request
class SignInRequest {
  final String email;
  final String password;

  const SignInRequest({required this.email, required this.password});
}

/// Model for password reset request
class PasswordResetRequest {
  final String email;

  const PasswordResetRequest({required this.email});
}

/// Model for password update request
class PasswordUpdateRequest {
  final String newPassword;

  const PasswordUpdateRequest({required this.newPassword});
}
