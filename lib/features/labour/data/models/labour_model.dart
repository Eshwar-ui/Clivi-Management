import 'package:flutter/material.dart';

enum LabourStatus {
  active('active'),
  inactive('inactive');

  final String value;
  const LabourStatus(this.value);

  static LabourStatus fromString(String value) {
    return LabourStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LabourStatus.active,
    );
  }

  Color get color {
    switch (this) {
      case LabourStatus.active:
        return Colors.green;
      case LabourStatus.inactive:
        return Colors.grey;
    }
  }
}

class LabourModel {
  final String id;
  final String name;
  final String? phone;
  final String? skillType;
  final double? dailyWage;
  final String? projectId;
  final LabourStatus status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? projectName;

  LabourModel({
    required this.id,
    required this.name,
    this.phone,
    this.skillType,
    this.dailyWage,
    this.projectId,
    this.status = LabourStatus.active,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.projectName,
  });

  factory LabourModel.fromJson(Map<String, dynamic> json) {
    return LabourModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      skillType: json['skill_type'] as String?,
      dailyWage: (json['daily_wage'] as num?)?.toDouble(),
      projectId: json['project_id'] as String?,
      status: LabourStatus.fromString(json['status'] as String? ?? 'active'),
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      projectName: json['projects']?['name'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'phone': phone,
      'skill_type': skillType,
      'daily_wage': dailyWage,
      'project_id': projectId,
      'status': status.value,
      'created_by': createdBy,
    };
  }

  LabourModel copyWith({
    String? name,
    String? phone,
    String? skillType,
    double? dailyWage,
    String? projectId,
    LabourStatus? status,
  }) {
    return LabourModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      skillType: skillType ?? this.skillType,
      dailyWage: dailyWage ?? this.dailyWage,
      projectId: projectId ?? this.projectId,
      status: status ?? this.status,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      projectName: projectName,
    );
  }
}

/// Common skill types for construction workers
class SkillTypes {
  static const List<String> all = [
    'Mason',
    'Carpenter',
    'Electrician',
    'Plumber',
    'Painter',
    'Welder',
    'Helper',
    'Supervisor',
    'Driver',
    'Crane Operator',
    'Other',
  ];
}
