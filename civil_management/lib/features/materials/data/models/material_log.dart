import 'stock_item.dart';
import '../../../../features/inventory/data/models/supplier_model.dart';

class MaterialLog {
  final String id;
  final String projectId;
  final String itemId;
  final String logType; // 'inward', 'outward'
  final double quantity;
  final String? activity;
  final String? notes;
  final String? loggedBy;
  final DateTime loggedAt;

  // Additional fields
  final String? grade;
  final double? billAmount;
  final String? paymentType;

  // Relations
  final StockItem? stockItem;
  final SupplierModel? supplier;

  const MaterialLog({
    required this.id,
    required this.projectId,
    required this.itemId,
    required this.logType,
    required this.quantity,
    this.activity,
    this.notes,
    this.loggedBy,
    required this.loggedAt,
    this.grade,
    this.billAmount,
    this.paymentType,
    this.stockItem,
    this.supplier,
  });

  factory MaterialLog.fromJson(Map<String, dynamic> json) {
    return MaterialLog(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      itemId: json['item_id']?.toString() ?? '',
      logType: json['log_type']?.toString() ?? 'inward',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      activity: json['activity'] as String?,
      notes: json['notes'] as String?,
      loggedBy: json['logged_by'] as String?,
      loggedAt: json['logged_at'] != null
          ? DateTime.parse(json['logged_at'] as String)
          : DateTime.now(),

      grade: json['grade'] as String?,
      billAmount: (json['bill_amount'] as num?)?.toDouble(),
      paymentType: json['payment_type'] as String?,

      stockItem: json['stock_item'] != null
          ? StockItem.fromJson(json['stock_item'] as Map<String, dynamic>)
          : null,
      supplier: json['supplier'] != null
          ? SupplierModel.fromJson(json['supplier'] as Map<String, dynamic>)
          : null,
    );
  }
}
