class MachineryLog {
  final String id;
  final String projectId;
  final String machineryId;
  final String workActivity;

  // Legacy / Meter based
  final double? startReading;
  final double? endReading;
  final double? executionHours;

  // Time based
  final DateTime? logDate;
  final String? startTime; // Format: HH:mm
  final String? endTime; // Format: HH:mm
  final double? hoursUsed; // New field 'hours_used'
  final double? totalHours; // Deprecated 'total_hours'
  final String? logType; // New field 'log_type'

  final String? notes;
  final String? loggedBy;
  final DateTime loggedAt;

  // Joined
  final String? machineryName;
  final String? machineryType;
  final String? registrationNo;

  const MachineryLog({
    required this.id,
    required this.projectId,
    required this.machineryId,
    required this.workActivity,
    this.startReading,
    this.endReading,
    this.executionHours,
    this.logDate,
    this.startTime,
    this.endTime,
    this.hoursUsed,
    this.totalHours,
    this.logType,
    this.notes,
    this.loggedBy,
    required this.loggedAt,
    this.machineryName,
    this.machineryType,
    this.registrationNo,
  });

  /// Get effective duration in hours
  double get duration => hoursUsed ?? totalHours ?? executionHours ?? 0.0;

  factory MachineryLog.fromJson(Map<String, dynamic> json) {
    return MachineryLog(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      machineryId: json['machinery_id'] as String,
      workActivity: json['work_activity'] as String,

      startReading: json['start_reading'] != null
          ? (json['start_reading'] as num).toDouble()
          : null,
      endReading: json['end_reading'] != null
          ? (json['end_reading'] as num).toDouble()
          : null,
      executionHours: json['execution_hours'] != null
          ? (json['execution_hours'] as num).toDouble()
          : null,

      logDate: json['log_date'] != null
          ? DateTime.parse(json['log_date'] as String)
          : null,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,

      hoursUsed: json['hours_used'] != null
          ? (json['hours_used'] as num).toDouble()
          : null,
      totalHours: json['total_hours'] != null
          ? (json['total_hours'] as num).toDouble()
          : null,
      logType: json['log_type'] as String?,

      notes: json['notes'] as String?,
      loggedBy: json['logged_by'] as String?,
      loggedAt: DateTime.parse(json['logged_at'] as String),

      machineryName: json['machinery'] != null
          ? json['machinery']['name'] as String?
          : null,
      machineryType: json['machinery'] != null
          ? json['machinery']['type'] as String?
          : null,
      registrationNo: json['machinery'] != null
          ? json['machinery']['registration_no'] as String?
          : null,
    );
  }
}
