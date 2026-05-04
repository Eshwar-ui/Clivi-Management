/// User profile data model with JSON serialization
/// Maps to the `user_profiles` table in Supabase
class UserProfileModel {
  final String id;
  final String? email;
  final String role;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String? companyId;
  final String? position;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfileModel({
    required this.id,
    this.email,
    required this.role,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.companyId,
    this.position,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON (Supabase response)
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'site_manager',
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      companyId: json['company_id'] as String?,
      position: json['position'] as String?,
      address: json['address'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (email != null) 'email': email,
      'role': role,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      if (companyId != null) 'company_id': companyId,
      if (position != null) 'position': position,
      if (address != null) 'address': address,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert to JSON for update (excludes id and created_at)
  Map<String, dynamic> toUpdateJson() {
    return {
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (position != null) 'position': position,
      if (address != null) 'address': address,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  UserProfileModel copyWith({
    String? id,
    String? email,
    String? role,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? companyId,
    String? position,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      companyId: companyId ?? this.companyId,
      position: position ?? this.position,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserProfileModel(id: $id, email: $email, role: $role, fullName: $fullName, position: $position)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfileModel &&
        other.id == id &&
        other.email == email &&
        other.role == role &&
        other.fullName == fullName &&
        other.phone == phone &&
        other.avatarUrl == avatarUrl &&
        other.companyId == companyId &&
        other.position == position &&
        other.address == address;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        role.hashCode ^
        fullName.hashCode ^
        phone.hashCode ^
        avatarUrl.hashCode ^
        companyId.hashCode ^
        position.hashCode ^
        address.hashCode;
  }
}
