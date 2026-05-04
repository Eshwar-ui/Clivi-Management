class MachineryModel {
  final String id;
  final String name;
  final String? type;
  final String? registrationNo;
  final double currentReading;
  final double totalHours;
  final String status;
  final String? ownershipType; // Own / Rental
  final String? currentProjectId;
  final DateTime? purchaseDate;
  final DateTime? lastService;

  const MachineryModel({
    required this.id,
    required this.name,
    this.type,
    this.registrationNo,
    required this.currentReading,
    required this.totalHours,
    required this.status,
    this.ownershipType,
    this.currentProjectId,
    this.purchaseDate,
    this.lastService,
  });

  factory MachineryModel.fromJson(Map<String, dynamic> json) {
    return MachineryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String?,
      registrationNo: json['registration_no'] as String?,
      currentReading: (json['current_reading'] as num?)?.toDouble() ?? 0.0,
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'active',
      ownershipType: json['ownership_type'] as String?,
      currentProjectId: json['current_project_id'] as String?,
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'] as String)
          : null,
      lastService: json['last_service'] != null
          ? DateTime.parse(json['last_service'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'registration_no': registrationNo,
      'current_reading': currentReading,
      'total_hours': totalHours,
      'status': status,
      'ownership_type': ownershipType,
      'current_project_id': currentProjectId,
      'purchase_date': purchaseDate?.toIso8601String().split('T').first,
      'last_service': lastService?.toIso8601String().split('T').first,
    };
  }
}
