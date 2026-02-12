enum MaterialAnalyticsTab {
  steel(
    label: 'Steel',
    supplierCategory: 'Steel',
    keywords: [
      'steel',
      'tmt',
      'rebar',
      'iron',
      'rod',
      'bar',
      'fe',
      'saria',
      'ms',
      'channel',
      'angle',
      'plate',
    ],
  ),
  cement(
    label: 'Cement',
    supplierCategory: 'Cement',
    keywords: [
      'cement',
      'concrete',
      'opc',
      'ppc',
      'ultratech',
      'acc',
      'ambuja',
      'birla',
    ],
  );

  final String label;
  final String supplierCategory;
  final List<String> keywords;

  const MaterialAnalyticsTab({
    required this.label,
    required this.supplierCategory,
    required this.keywords,
  });
}

enum VendorChartMetric { quantity, amount }

/// Model for vendor payment summary view
class VendorPaymentSummary {
  final String vendorId;
  final String vendorName;
  final String? vendorType;
  final double? creditLimit;
  final int totalInvoices;
  final double totalInvoiceAmount;
  final double totalPaid;
  final double totalBalance;
  final DateTime? lastTransactionDate;

  const VendorPaymentSummary({
    required this.vendorId,
    required this.vendorName,
    this.vendorType,
    this.creditLimit,
    required this.totalInvoices,
    required this.totalInvoiceAmount,
    required this.totalPaid,
    required this.totalBalance,
    this.lastTransactionDate,
  });

  factory VendorPaymentSummary.fromJson(Map<String, dynamic> json) {
    return VendorPaymentSummary(
      vendorId: json['vendor_id'] as String,
      vendorName: json['vendor_name'] as String,
      vendorType: json['vendor_type'] as String?,
      creditLimit: json['credit_limit'] != null
          ? (json['credit_limit'] as num).toDouble()
          : null,
      totalInvoices: json['total_invoices'] as int? ?? 0,
      totalInvoiceAmount:
          (json['total_invoice_amount'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0.0,
      lastTransactionDate: json['last_transaction_date'] != null
          ? DateTime.parse(json['last_transaction_date'] as String)
          : null,
    );
  }

  /// Calculate utilization percentage if credit limit exists
  double? get creditUtilization {
    if (creditLimit == null || creditLimit == 0) return null;
    return (totalBalance / creditLimit!) * 100;
  }
}

/// Model for vendor stock summary view
class VendorStockSummary {
  final String vendorId;
  final String vendorName;
  final String? vendorType;
  final String? materialName;
  final String? grade;
  final String? projectId;
  final String? projectName;
  final double? lastPrice;
  final DateTime? lastUsedAt;
  final double currentStock;

  const VendorStockSummary({
    required this.vendorId,
    required this.vendorName,
    this.vendorType,
    this.materialName,
    this.grade,
    this.projectId,
    this.projectName,
    this.lastPrice,
    this.lastUsedAt,
    required this.currentStock,
  });

  factory VendorStockSummary.fromJson(Map<String, dynamic> json) {
    return VendorStockSummary(
      vendorId: json['vendor_id'] as String,
      vendorName: json['vendor_name'] as String,
      vendorType: json['vendor_type'] as String?,
      materialName: json['material_name'] as String?,
      grade: json['grade'] as String?,
      projectId: json['project_id'] as String?,
      projectName: json['project_name'] as String?,
      lastPrice: json['last_price'] != null
          ? (json['last_price'] as num).toDouble()
          : null,
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Model for project inventory summary view
class ProjectInventorySummary {
  final String projectId;
  final String projectName;
  final String? category; // 'Steel', 'Cement'
  final String? materialName;
  final String? grade;
  final String? unit;
  final double totalQuantity;
  final double? avgUnitPrice;
  final double totalValue;

  const ProjectInventorySummary({
    required this.projectId,
    required this.projectName,
    this.category,
    this.materialName,
    this.grade,
    this.unit,
    required this.totalQuantity,
    this.avgUnitPrice,
    required this.totalValue,
  });

  factory ProjectInventorySummary.fromJson(Map<String, dynamic> json) {
    return ProjectInventorySummary(
      projectId: json['project_id'] as String,
      projectName: json['project_name'] as String,
      category: json['category'] as String?,
      materialName: json['material_name'] as String?,
      grade: json['grade'] as String?,
      unit: json['unit'] as String?,
      totalQuantity: (json['total_quantity'] as num?)?.toDouble() ?? 0.0,
      avgUnitPrice: json['avg_unit_price'] != null
          ? (json['avg_unit_price'] as num).toDouble()
          : null,
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Aggregated quantity per vendor across all projects (from get_vendor_overview RPC)
class VendorOverview {
  final String vendorId;
  final String vendorName;
  final double totalQuantity;

  const VendorOverview({
    required this.vendorId,
    required this.vendorName,
    required this.totalQuantity,
  });

  factory VendorOverview.fromJson(Map<String, dynamic> json) {
    return VendorOverview(
      vendorId: json['vendor_id'] as String,
      vendorName: json['vendor_name'] as String? ?? 'Unknown Vendor',
      totalQuantity: (json['total_qty'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Per-vendor breakdown returned by get_vendor_material_totals RPC
class VendorMaterialTotal {
  final String projectId;
  final String projectName;
  final String materialName;
  final double totalInward;
  final double totalOutward;
  final double net;

  const VendorMaterialTotal({
    required this.projectId,
    required this.projectName,
    required this.materialName,
    required this.totalInward,
    required this.totalOutward,
    required this.net,
  });

  factory VendorMaterialTotal.fromJson(Map<String, dynamic> json) {
    return VendorMaterialTotal(
      projectId: json['project_id'] as String,
      projectName: json['project_name'] as String? ?? 'Unknown Project',
      materialName: json['material_name'] as String? ?? 'Unknown',
      totalInward: (json['total_inward'] as num?)?.toDouble() ?? 0.0,
      totalOutward: (json['total_outward'] as num?)?.toDouble() ?? 0.0,
      net: (json['net'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Line-level inward material entry used for supply details UI.
class VendorSupplyLine {
  final String vendorId;
  final String vendorName;
  final String projectId;
  final String projectName;
  final String materialName;
  final String? materialCategory;
  final String unit;
  final double quantity;
  final double amount;
  final DateTime loggedAt;

  const VendorSupplyLine({
    required this.vendorId,
    required this.vendorName,
    required this.projectId,
    required this.projectName,
    required this.materialName,
    this.materialCategory,
    required this.unit,
    required this.quantity,
    required this.amount,
    required this.loggedAt,
  });
}

class VendorMaterialAggregate {
  final String vendorId;
  final String vendorName;
  final Map<String, double> quantityByUnit;
  final double totalAmount;
  final String? topProjectId;
  final String? topProjectName;
  final DateTime? lastReceivedAt;

  const VendorMaterialAggregate({
    required this.vendorId,
    required this.vendorName,
    required this.quantityByUnit,
    required this.totalAmount,
    this.topProjectId,
    this.topProjectName,
    this.lastReceivedAt,
  });

  double get quantityForChart =>
      quantityByUnit.values.fold(0.0, (sum, qty) => sum + qty);

  String get quantityDisplay => formatQuantityByUnit(quantityByUnit);
}

class VendorProjectAggregate {
  final String vendorId;
  final String vendorName;
  final String projectId;
  final String projectName;
  final Map<String, double> quantityByUnit;
  final double totalAmount;
  final DateTime? lastReceivedAt;
  final List<VendorSupplyLine> previewLines;

  const VendorProjectAggregate({
    required this.vendorId,
    required this.vendorName,
    required this.projectId,
    required this.projectName,
    required this.quantityByUnit,
    required this.totalAmount,
    required this.previewLines,
    this.lastReceivedAt,
  });

  String get quantityDisplay => formatQuantityByUnit(quantityByUnit);
}

String formatQuantityByUnit(Map<String, double> quantityByUnit) {
  if (quantityByUnit.isEmpty) return '0';

  final entries = quantityByUnit.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final primary = entries.first;
  final primaryText = '${_formatNumber(primary.value)} ${primary.key}';
  if (entries.length == 1) return primaryText;

  return '$primaryText + ${entries.length - 1} units';
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}
