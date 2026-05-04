class StockItem {
  final String id;
  final String projectId;
  final String name;
  final String? grade;
  final String unit;
  final double quantity;
  final DateTime createdAt;

  const StockItem({
    required this.id,
    required this.projectId,
    required this.name,
    this.grade,
    required this.unit,
    required this.quantity,
    required this.createdAt,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Material',
      grade: json['grade'] as String?,
      unit: json['unit']?.toString() ?? 'units',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'name': name,
      'grade': grade,
      'unit': unit,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
