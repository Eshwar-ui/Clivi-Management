class DailyLabourLog {
  final String id;
  final String projectId;
  final String? labourId;
  final String contractorName;
  final int skilledCount;
  final int unskilledCount;
  final DateTime logDate;
  final String? notes; // optional
  final String? createdBy;

  DailyLabourLog({
    required this.id,
    required this.projectId,
    this.labourId,
    required this.contractorName,
    required this.skilledCount,
    required this.unskilledCount,
    required this.logDate,
    this.notes,
    this.createdBy,
  });

  factory DailyLabourLog.fromJson(Map<String, dynamic> json) {
    return DailyLabourLog(
      id: json['id'],
      projectId: json['project_id'],
      labourId: json['labour_id'],
      contractorName: json['contractor_name'],
      skilledCount: json['skilled_count'] ?? 0,
      unskilledCount: json['unskilled_count'] ?? 0,
      logDate: DateTime.parse(json['log_date']),
      notes: json['notes'],
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'labour_id': labourId,
      'contractor_name': contractorName,
      'skilled_count': skilledCount,
      'unskilled_count': unskilledCount,
      'log_date': logDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'notes': notes,
      'created_by': createdBy,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'project_id': projectId,
      'labour_id': labourId,
      'contractor_name': contractorName,
      'skilled_count': skilledCount,
      'unskilled_count': unskilledCount,
      'log_date': logDate.toIso8601String().split('T')[0],
      'notes': notes,
      // created_by is handled by RLS typically, or we can send it if we have it.
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}
