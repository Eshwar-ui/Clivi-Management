enum AttendanceStatus {
  present('present'),
  absent('absent'),
  halfDay('half_day');

  final String value;
  const AttendanceStatus(this.value);

  static AttendanceStatus fromString(String value) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AttendanceStatus.present,
    );
  }

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.halfDay:
        return 'Half Day';
    }
  }
}

class LabourAttendanceModel {
  final String id;
  final String labourId;
  final String projectId;
  final DateTime date;
  final AttendanceStatus status;
  final double? hoursWorked;
  final String? notes;
  final String? recordedBy;
  final DateTime createdAt;

  // Joined data
  final String? labourName;
  final String? labourPhone;
  final String? skillType;
  final double? dailyWage;

  LabourAttendanceModel({
    required this.id,
    required this.labourId,
    required this.projectId,
    required this.date,
    required this.status,
    this.hoursWorked,
    this.notes,
    this.recordedBy,
    required this.createdAt,
    this.labourName,
    this.labourPhone,
    this.skillType,
    this.dailyWage,
  });

  factory LabourAttendanceModel.fromJson(Map<String, dynamic> json) {
    return LabourAttendanceModel(
      id: json['id'] as String,
      labourId: json['labour_id'] as String,
      projectId: json['project_id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: AttendanceStatus.fromString(
        json['status'] as String? ?? 'present',
      ),
      hoursWorked: (json['hours_worked'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      recordedBy: json['recorded_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      labourName: json['labour']?['name'] as String?,
      labourPhone: json['labour']?['phone'] as String?,
      skillType: json['labour']?['skill_type'] as String?,
      dailyWage: (json['labour']?['daily_wage'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'labour_id': labourId,
      'project_id': projectId,
      'date': date.toIso8601String().split('T')[0],
      'status': status.value,
      'hours_worked': hoursWorked,
      'notes': notes,
      'recorded_by': recordedBy,
    };
  }

  double get earnedAmount {
    if (dailyWage == null) return 0;
    switch (status) {
      case AttendanceStatus.present:
        return dailyWage!;
      case AttendanceStatus.halfDay:
        return dailyWage! / 2;
      case AttendanceStatus.absent:
        return 0;
    }
  }
}
