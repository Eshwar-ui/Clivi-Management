/// Material log model - tracks inward/outward material movements
enum LogType {
  inward('inward'),
  outward('outward');

  final String value;
  const LogType(this.value);

  static LogType fromString(String? type) {
    if (type == 'outward') return LogType.outward;
    return LogType.inward;
  }

  String get displayName => this == LogType.inward ? 'Received' : 'Used';
}

class MaterialLogModel {
  final String id;
  final String projectId;
  final String itemId;
  final LogType logType;
  final double quantity;
  final String? activity;
  final String? challanUrl;
  final String? loggedBy;
  final DateTime? loggedAt;
  final String? notes;

  // Joined data
  final String? itemName;
  final String? itemUnit;

  // Supplier info (for inward logs)
  final String? supplierId;
  final String? supplierName;

  const MaterialLogModel({
    required this.id,
    required this.projectId,
    required this.itemId,
    required this.logType,
    required this.quantity,
    this.activity,
    this.challanUrl,
    this.loggedBy,
    this.loggedAt,
    this.notes,
    this.itemName,
    this.itemUnit,
    this.supplierId,
    this.supplierName,
  });

  factory MaterialLogModel.fromJson(Map<String, dynamic> json) {
    // Handle nested stock_items data
    final stockItem = json['stock_items'] as Map<String, dynamic>?;
    // Handle nested supplier data
    final supplier = json['suppliers'] as Map<String, dynamic>?;

    return MaterialLogModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      itemId: json['item_id'] as String,
      logType: LogType.fromString(json['log_type'] as String?),
      quantity: double.tryParse(json['quantity'].toString()) ?? 0,
      activity: json['activity'] as String?,
      challanUrl: json['challan_url'] as String?,
      loggedBy: json['logged_by'] as String?,
      loggedAt: json['logged_at'] != null
          ? DateTime.parse(json['logged_at'] as String)
          : null,
      notes: json['notes'] as String?,
      itemName: stockItem?['name'] as String?,
      itemUnit: stockItem?['unit'] as String?,
      supplierId: json['supplier_id'] as String?,
      supplierName: supplier?['name'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'project_id': projectId,
      'item_id': itemId,
      'log_type': logType.value,
      'quantity': quantity,
      'activity': activity,
      'challan_url': challanUrl,
      'notes': notes,
      if (supplierId != null) 'supplier_id': supplierId,
    };
  }

  @override
  String toString() =>
      'MaterialLog(${logType.displayName}: $quantity ${itemUnit ?? ''} of ${itemName ?? itemId})';
}

/// Common activities for outward logs
class MaterialActivities {
  static const List<String> commonActivities = [
    'Foundation Work',
    'Slab Casting',
    'Column Casting',
    'Beam Casting',
    'Plastering',
    'Brickwork',
    'Flooring',
    'Roofing',
    'Waterproofing',
    'Painting',
    'Other',
  ];
}
