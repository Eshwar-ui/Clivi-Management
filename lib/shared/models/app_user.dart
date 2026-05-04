import '../../features/auth/providers/auth_provider.dart';

/// App user model representing an authenticated user
/// This is a unified user model combining Supabase User and user profile data
class AppUser {
  /// Unique user ID (from Supabase Auth)
  final String id;

  /// User email address
  final String email;

  /// User role (super_admin, admin, site_manager)
  final UserRole role;

  /// Full name of the user
  final String? fullName;

  /// Phone number
  final String? phone;

  /// Avatar/profile picture URL
  final String? avatarUrl;

  /// Whether email is verified
  final bool emailVerified;

  /// Account creation timestamp
  final DateTime? createdAt;

  /// Last update timestamp
  final DateTime? updatedAt;

  /// Last sign-in timestamp
  final DateTime? lastSignInAt;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.emailVerified = false,
    this.createdAt,
    this.updatedAt,
    this.lastSignInAt,
    this.metadata,
  });

  /// Create AppUser from JSON (combining auth and profile data)
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role:
          UserRole.fromString(json['role'] as String?) ?? UserRole.siteManager,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      lastSignInAt: json['last_sign_in_at'] != null
          ? DateTime.parse(json['last_sign_in_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.value,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'email_verified': emailVerified,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_sign_in_at': lastSignInAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  AppUser copyWith({
    String? id,
    String? email,
    UserRole? role,
    String? fullName,
    String? phone,
    String? avatarUrl,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSignInAt,
    Map<String, dynamic>? metadata,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // ============================================================
  // PERMISSION HELPERS
  // ============================================================

  /// Check if user is Super Admin
  bool get isSuperAdmin => role == UserRole.superAdmin;

  /// Check if user is Admin (includes Super Admin)
  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;

  /// Check if user is Site Manager
  bool get isSiteManager => role == UserRole.siteManager;

  /// Check if user has at least the given role level
  bool isAtLeast(UserRole minRole) {
    const hierarchy = [
      UserRole.siteManager,
      UserRole.admin,
      UserRole.superAdmin,
    ];
    return hierarchy.indexOf(role) >= hierarchy.indexOf(minRole);
  }

  /// Check if user can manage other users
  bool get canManageUsers => isSuperAdmin;

  /// Check if user can create projects
  bool get canCreateProjects => isAdmin;

  /// Check if user can delete projects
  bool get canDeleteProjects => isSuperAdmin;

  /// Check if user can manage stock
  bool get canManageStock => isAdmin;

  /// Check if user can view reports
  bool get canViewReports => isAdmin;

  /// Check if user can generate reports
  bool get canGenerateReports => isSuperAdmin;

  // ============================================================
  // DISPLAY HELPERS
  // ============================================================

  /// Get display name (full name or email)
  String get displayName => fullName?.isNotEmpty == true ? fullName! : email;

  /// Get initials for avatar
  String get initials {
    if (fullName?.isNotEmpty == true) {
      final names = fullName!.trim().split(' ');
      if (names.length >= 2) {
        return '${names.first[0]}${names.last[0]}'.toUpperCase();
      }
      return names.first
          .substring(0, names.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return email.substring(0, 2).toUpperCase();
  }

  /// Get role display name
  String get roleDisplayName => role.displayName;

  /// Check if profile is complete
  bool get isProfileComplete =>
      fullName?.isNotEmpty == true && phone?.isNotEmpty == true;

  /// Get profile completion percentage
  int get profileCompletion {
    int complete = 0;
    const total = 4;

    if (fullName?.isNotEmpty == true) complete++;
    if (phone?.isNotEmpty == true) complete++;
    if (avatarUrl?.isNotEmpty == true) complete++;
    if (emailVerified) complete++;

    return ((complete / total) * 100).round();
  }

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, role: ${role.value}, fullName: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser &&
        other.id == id &&
        other.email == email &&
        other.role == role &&
        other.fullName == fullName &&
        other.phone == phone &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        role.hashCode ^
        fullName.hashCode ^
        phone.hashCode ^
        avatarUrl.hashCode;
  }
}

/// User permissions model for fine-grained access control
class UserPermissions {
  final bool canViewProjects;
  final bool canCreateProjects;
  final bool canEditProjects;
  final bool canDeleteProjects;

  final bool canViewStock;
  final bool canManageStock;

  final bool canViewLabour;
  final bool canManageLabour;

  final bool canViewBills;
  final bool canManageBills;

  final bool canViewBlueprints;
  final bool canUploadBlueprints;

  final bool canViewMachinery;
  final bool canManageMachinery;

  final bool canViewReports;
  final bool canGenerateReports;

  final bool canManageUsers;
  final bool canManageRoles;

  const UserPermissions({
    this.canViewProjects = true,
    this.canCreateProjects = false,
    this.canEditProjects = false,
    this.canDeleteProjects = false,
    this.canViewStock = true,
    this.canManageStock = false,
    this.canViewLabour = true,
    this.canManageLabour = false,
    this.canViewBills = true,
    this.canManageBills = false,
    this.canViewBlueprints = true,
    this.canUploadBlueprints = false,
    this.canViewMachinery = true,
    this.canManageMachinery = false,
    this.canViewReports = false,
    this.canGenerateReports = false,
    this.canManageUsers = false,
    this.canManageRoles = false,
  });

  /// Get permissions for Super Admin (full access)
  factory UserPermissions.superAdmin() {
    return const UserPermissions(
      canViewProjects: true,
      canCreateProjects: true,
      canEditProjects: true,
      canDeleteProjects: true,
      canViewStock: true,
      canManageStock: true,
      canViewLabour: true,
      canManageLabour: true,
      canViewBills: true,
      canManageBills: true,
      canViewBlueprints: true,
      canUploadBlueprints: true,
      canViewMachinery: true,
      canManageMachinery: true,
      canViewReports: true,
      canGenerateReports: true,
      canManageUsers: true,
      canManageRoles: true,
    );
  }

  /// Get permissions for Admin
  factory UserPermissions.admin() {
    return const UserPermissions(
      canViewProjects: true,
      canCreateProjects: true,
      canEditProjects: true,
      canDeleteProjects: false,
      canViewStock: true,
      canManageStock: true,
      canViewLabour: true,
      canManageLabour: true,
      canViewBills: true,
      canManageBills: true,
      canViewBlueprints: true,
      canUploadBlueprints: true,
      canViewMachinery: true,
      canManageMachinery: true,
      canViewReports: true,
      canGenerateReports: false,
      canManageUsers: false,
      canManageRoles: false,
    );
  }

  /// Get permissions for Site Manager
  factory UserPermissions.siteManager() {
    return const UserPermissions(
      canViewProjects: true,
      canCreateProjects: false,
      canEditProjects: false,
      canDeleteProjects: false,
      canViewStock: true,
      canManageStock: false,
      canViewLabour: true,
      canManageLabour: true,
      canViewBills: true,
      canManageBills: false,
      canViewBlueprints: true,
      canUploadBlueprints: true,
      canViewMachinery: true,
      canManageMachinery: false,
      canViewReports: false,
      canGenerateReports: false,
      canManageUsers: false,
      canManageRoles: false,
    );
  }

  /// Get permissions based on user role
  factory UserPermissions.fromRole(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return UserPermissions.superAdmin();
      case UserRole.admin:
        return UserPermissions.admin();
      case UserRole.siteManager:
        return UserPermissions.siteManager();
    }
  }
}
