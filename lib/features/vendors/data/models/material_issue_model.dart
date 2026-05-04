class MaterialIssue {
  final String id;
  final String projectId;
  final String issueNumber;
  final DateTime issueDate;
  final String? stockItemId;
  final String materialName;
  final double quantity;
  final String? unit;
  final String? grade;
  final String? issuedTo;
  final String? purpose;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  const MaterialIssue({
    required this.id,
    required this.projectId,
    required this.issueNumber,
    required this.issueDate,
    this.stockItemId,
    required this.materialName,
    required this.quantity,
    this.unit,
    this.grade,
    this.issuedTo,
    this.purpose,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  factory MaterialIssue.fromJson(Map<String, dynamic> json) {
    return MaterialIssue(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      issueNumber: json['issue_number'] as String,
      issueDate: DateTime.parse(json['issue_date'] as String),
      stockItemId: json['stock_item_id'] as String?,
      materialName: json['material_name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String?,
      grade: json['grade'] as String?,
      issuedTo: json['issued_to'] as String?,
      purpose: json['purpose'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'issue_number': issueNumber,
      'issue_date': issueDate.toIso8601String().split('T')[0],
      'stock_item_id': stockItemId,
      'material_name': materialName,
      'quantity': quantity,
      'unit': unit,
      'grade': grade,
      'issued_to': issuedTo,
      'purpose': purpose,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
