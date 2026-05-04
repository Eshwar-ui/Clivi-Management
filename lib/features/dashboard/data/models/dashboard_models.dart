// Dashboard data models
// Contains models for dashboard statistics, operation logs, and project summaries

/// Dashboard statistics model
/// Returned by get_dashboard_stats RPC
class DashboardStats {
  final int activeProjects;
  final int totalProjects;
  final int totalWorkers;
  final int lowStockItems;
  final int pendingReports;
  final int blueprintsCount;
  final double growthPercentage;
  final DateTime? lastUpdated;

  const DashboardStats({
    this.activeProjects = 0,
    this.totalProjects = 0,
    this.totalWorkers = 0,
    this.lowStockItems = 0,
    this.pendingReports = 0,
    this.blueprintsCount = 0,
    this.growthPercentage = 0.0,
    this.lastUpdated,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      activeProjects: json['active_projects'] as int? ?? 0,
      totalProjects: json['total_projects'] as int? ?? 0,
      totalWorkers: json['total_workers'] as int? ?? 0,
      lowStockItems: json['low_stock_items'] as int? ?? 0,
      pendingReports: json['pending_reports'] as int? ?? 0,
      blueprintsCount: json['blueprints_count'] as int? ?? 0,
      growthPercentage: (json['growth_percentage'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'active_projects': activeProjects,
      'total_projects': totalProjects,
      'total_workers': totalWorkers,
      'low_stock_items': lowStockItems,
      'pending_reports': pendingReports,
      'blueprints_count': blueprintsCount,
      'growth_percentage': growthPercentage,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  /// Empty stats for loading state
  static const empty = DashboardStats();

  @override
  String toString() {
    return 'DashboardStats(activeProjects: $activeProjects, totalWorkers: $totalWorkers)';
  }
}

/// Operation log entry for activity feed
class OperationLog {
  final String id;
  final String operationType;
  final String entityType;
  final String title;
  final String? description;
  final String? projectName;
  final String? userName;
  final DateTime createdAt;

  const OperationLog({
    required this.id,
    required this.operationType,
    required this.entityType,
    required this.title,
    this.description,
    this.projectName,
    this.userName,
    required this.createdAt,
  });

  factory OperationLog.fromJson(Map<String, dynamic> json) {
    return OperationLog(
      id: json['id'] as String,
      operationType: json['operation_type'] as String,
      entityType: json['entity_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      projectName: json['project_name'] as String?,
      userName: json['user_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation_type': operationType,
      'entity_type': entityType,
      'title': title,
      'description': description,
      'project_name': projectName,
      'user_name': userName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get icon data based on operation type
  String get iconName {
    switch (entityType) {
      case 'project':
        return 'business';
      case 'stock':
        return 'inventory';
      case 'labour':
        return 'people';
      case 'blueprint':
        return 'description';
      case 'machinery':
        return 'build';
      case 'attendance':
        return 'schedule';
      case 'report':
        return 'assignment';
      default:
        return 'info';
    }
  }

  /// Get color key based on operation type
  String get colorKey {
    switch (operationType) {
      case 'create':
        return 'success';
      case 'update':
        return 'info';
      case 'delete':
        return 'error';
      case 'upload':
        return 'primary';
      case 'status_change':
        return 'warning';
      default:
        return 'info';
    }
  }

  /// Get relative time string
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}

/// Project summary for dashboard preview cards
class ProjectSummary {
  final String id;
  final String name;
  final String? projectType;
  final String status;
  final int progress;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? location;

  const ProjectSummary({
    required this.id,
    required this.name,
    this.projectType,
    required this.status,
    this.progress = 0,
    this.startDate,
    this.endDate,
    this.location,
  });

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    return ProjectSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      projectType: json['project_type'] as String?,
      status: json['status'] as String,
      progress: json['progress'] as int? ?? 0,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      location: json['location'] as String?,
    );
  }

  /// Format project type for display
  String get displayType {
    if (projectType == null) return 'Project';
    return projectType!
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// Calculate days remaining
  int? get daysRemaining {
    if (endDate == null) return null;
    final remaining = endDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }
}
