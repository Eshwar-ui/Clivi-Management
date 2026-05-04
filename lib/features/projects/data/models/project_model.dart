import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Project type enum
enum ProjectType {
  residential('Residential'),
  commercial('Commercial'),
  infrastructure('Infrastructure'),
  industrial('Industrial');

  final String value;
  const ProjectType(this.value);

  static ProjectType? fromString(String? type) {
    if (type == null) return null;
    return ProjectType.values.firstWhere(
      (t) => t.value == type,
      orElse: () => ProjectType.residential,
    );
  }

  Color get color {
    switch (this) {
      case ProjectType.residential:
        return AppColors.info;
      case ProjectType.commercial:
        return AppColors.warning;
      case ProjectType.infrastructure:
        return AppColors.success;
      case ProjectType.industrial:
        return AppColors.admin;
    }
  }
}

/// Project data model
/// Maps to the `projects` table in Supabase
class ProjectModel {
  final String id;
  final String name;
  final String? clientName;
  final String? description;
  final String? location;
  final ProjectType? projectType;
  final ProjectStatus status;
  final int progress;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? budget;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  // Joined data
  final List<ProjectAssignmentModel>? assignments;
  final int? assignedManagersCount;

  const ProjectModel({
    required this.id,
    required this.name,
    this.clientName,
    this.description,
    this.location,
    this.projectType,
    this.status = ProjectStatus.inProgress,
    this.progress = 0,
    this.startDate,
    this.endDate,
    this.budget,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.assignments,
    this.assignedManagersCount,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      clientName: json['client_name'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      projectType: ProjectType.fromString(json['project_type'] as String?),
      status: ProjectStatus.fromString(json['status'] as String?),
      progress: json['progress'] as int? ?? 0,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      budget: json['budget'] != null
          ? double.tryParse(json['budget'].toString())
          : null,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      assignments: json['project_assignments'] != null
          ? (json['project_assignments'] as List)
                .map((e) => ProjectAssignmentModel.fromJson(e))
                .toList()
          : null,
      assignedManagersCount: json['assigned_managers_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'client_name': clientName,
      'description': description,
      'location': location,
      'project_type': projectType?.value,
      'status': status.value,
      'progress': progress,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'budget': budget,
    };
  }

  Map<String, dynamic> toInsertJson(String userId) {
    return {...toJson(), 'created_by': userId};
  }

  /// Get the primary manager (first assignment)
  ProjectAssignmentModel? get primaryManager {
    if (assignments == null || assignments!.isEmpty) return null;
    return assignments!.first;
  }

  /// Get manager display name
  String get managerName {
    return primaryManager?.userName ?? 'Not Assigned';
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? clientName,
    String? description,
    String? location,
    ProjectType? projectType,
    ProjectStatus? status,
    int? progress,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<ProjectAssignmentModel>? assignments,
    int? assignedManagersCount,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      description: description ?? this.description,
      location: location ?? this.location,
      projectType: projectType ?? this.projectType,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      assignments: assignments ?? this.assignments,
      assignedManagersCount:
          assignedManagersCount ?? this.assignedManagersCount,
    );
  }

  @override
  String toString() =>
      'ProjectModel(id: $id, name: $name, status: ${status.value})';
}

/// Project status enum with display name and color
enum ProjectStatus {
  planning('planning'),
  inProgress('in_progress'),
  onHold('on_hold'),
  completed('completed'),
  cancelled('cancelled');

  final String value;
  const ProjectStatus(this.value);

  static ProjectStatus fromString(String? status) {
    if (status == null) return ProjectStatus.inProgress;
    return ProjectStatus.values.firstWhere(
      (s) => s.value == status,
      orElse: () => ProjectStatus.inProgress,
    );
  }

  String get displayName {
    switch (this) {
      case ProjectStatus.planning:
        return 'Planning';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.onHold:
        return 'On Hold';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Status-specific color for UI display
  Color get color {
    switch (this) {
      case ProjectStatus.planning:
        return AppColors.info;
      case ProjectStatus.inProgress:
        return AppColors.success;
      case ProjectStatus.onHold:
        return AppColors.warning;
      case ProjectStatus.completed:
        return AppColors.primary;
      case ProjectStatus.cancelled:
        return AppColors.error;
    }
  }

  bool get isActive =>
      this == ProjectStatus.planning || this == ProjectStatus.inProgress;
}

/// Project assignment model
/// Maps to `project_assignments` table
class ProjectAssignmentModel {
  final String id;
  final String projectId;
  final String userId;
  final String assignedRole;
  final DateTime? assignedAt;
  final String? assignedBy;

  // Joined user profile data
  final String? userName;
  final String? userPhone;
  final String? userAvatar;

  const ProjectAssignmentModel({
    required this.id,
    required this.projectId,
    required this.userId,
    this.assignedRole = 'member',
    this.assignedAt,
    this.assignedBy,
    this.userName,
    this.userPhone,
    this.userAvatar,
  });

  factory ProjectAssignmentModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user_profiles data
    final userProfile = json['user_profiles'] as Map<String, dynamic>?;

    return ProjectAssignmentModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      userId: json['user_id'] as String,
      assignedRole: json['assigned_role'] as String? ?? 'member',
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : null,
      assignedBy: json['assigned_by'] as String?,
      userName: userProfile?['full_name'] as String?,
      userPhone: userProfile?['phone'] as String?,
      userAvatar: userProfile?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'user_id': userId,
      'assigned_role': assignedRole,
    };
  }

  Map<String, dynamic> toInsertJson(String assignedByUserId) {
    return {...toJson(), 'assigned_by': assignedByUserId};
  }

  @override
  String toString() =>
      'ProjectAssignmentModel(projectId: $projectId, userId: $userId)';
}

/// Simple user model for site manager selection
class SiteManagerModel {
  final String id;
  final String? fullName;
  final String? phone;
  final String role;
  final bool isAssigned;

  const SiteManagerModel({
    required this.id,
    this.fullName,
    this.phone,
    this.role = 'site_manager',
    this.isAssigned = false,
  });

  factory SiteManagerModel.fromJson(
    Map<String, dynamic> json, {
    bool isAssigned = false,
  }) {
    return SiteManagerModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'site_manager',
      isAssigned: isAssigned,
    );
  }

  String get displayName => fullName ?? 'Unknown User';

  SiteManagerModel copyWith({bool? isAssigned}) {
    return SiteManagerModel(
      id: id,
      fullName: fullName,
      phone: phone,
      role: role,
      isAssigned: isAssigned ?? this.isAssigned,
    );
  }

  @override
  String toString() => 'SiteManagerModel(id: $id, name: $displayName)';
}

/// Project statistics model
/// Returned from get_project_stats RPC
class ProjectStats {
  final int materialReceived;
  final int materialConsumed;
  final int materialRemaining;
  final int laborCount;
  final int machineryCount;
  final int blueprintCount;

  const ProjectStats({
    this.materialReceived = 0,
    this.materialConsumed = 0,
    this.materialRemaining = 0,
    this.laborCount = 0,
    this.machineryCount = 0,
    this.blueprintCount = 0,
  });

  factory ProjectStats.fromJson(Map<String, dynamic> json) {
    return ProjectStats(
      materialReceived: json['material_received'] as int? ?? 0,
      materialConsumed: json['material_consumed'] as int? ?? 0,
      materialRemaining: json['material_remaining'] as int? ?? 0,
      laborCount: json['labor_count'] as int? ?? 0,
      machineryCount: json['machinery_count'] as int? ?? 0,
      blueprintCount: json['blueprint_count'] as int? ?? 0,
    );
  }

  static const empty = ProjectStats();
}

/// Material breakdown item
class MaterialBreakdown {
  final String name;
  final double received;
  final double consumed;
  final double remaining;
  final String? unit;

  const MaterialBreakdown({
    required this.name,
    this.received = 0,
    this.consumed = 0,
    this.remaining = 0,
    this.unit,
  });

  factory MaterialBreakdown.fromJson(Map<String, dynamic> json) {
    return MaterialBreakdown(
      name: json['name'] as String,
      received: (json['received'] as num?)?.toDouble() ?? 0.0,
      consumed: (json['consumed'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String?,
    );
  }
}
