// Reports and Analytics Models

/// Financial Statistics Model
/// Matches the JSON returned by get_financial_metrics RPC
class FinancialStats {
  final double totalExpenses;
  final double growthPercentage;
  final double laborCost;
  final double materialCost;
  final double machineryCost;
  final double otherCost;
  final List<ChartDataPoint> chartData;

  const FinancialStats({
    this.totalExpenses = 0,
    this.growthPercentage = 0,
    this.laborCost = 0,
    this.materialCost = 0,
    this.machineryCost = 0,
    this.otherCost = 0,
    this.chartData = const [],
  });

  factory FinancialStats.fromJson(Map<String, dynamic> json) {
    return FinancialStats(
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0,
      growthPercentage: (json['growth_percentage'] as num?)?.toDouble() ?? 0,
      laborCost: (json['labor_cost'] as num?)?.toDouble() ?? 0,
      materialCost: (json['material_cost'] as num?)?.toDouble() ?? 0,
      machineryCost: (json['machinery_cost'] as num?)?.toDouble() ?? 0,
      otherCost: (json['other_cost'] as num?)?.toDouble() ?? 0,
      chartData:
          (json['chart_data'] as List?)
              ?.map((e) => ChartDataPoint.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Empty state
  static const empty = FinancialStats();
}

/// Data point for charts
class ChartDataPoint {
  final String label;
  final double value;

  const ChartDataPoint({required this.label, required this.value});

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      label: json['label'] as String,
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Material movement summary for admin reporting.
/// Represents one material supplied by one vendor to one project.
class MaterialVendorReportRow {
  final String materialName;
  final String vendorName;
  final String projectId;
  final String projectName;
  final double totalReceived;
  final String unit;
  final DateTime? lastReceivedAt;

  const MaterialVendorReportRow({
    required this.materialName,
    required this.vendorName,
    required this.projectId,
    required this.projectName,
    required this.totalReceived,
    required this.unit,
    this.lastReceivedAt,
  });
}

/// Machinery usage summary for admin reporting.
/// Represents one machine used in one project.
class MachineryProjectReportRow {
  final String machineryName;
  final String machineryType;
  final String projectId;
  final String projectName;
  final double totalHours;
  final DateTime? lastWorkedAt;

  const MachineryProjectReportRow({
    required this.machineryName,
    required this.machineryType,
    required this.projectId,
    required this.projectName,
    required this.totalHours,
    required this.lastWorkedAt,
  });
}

/// Labour allocation summary for admin reporting.
/// Represents one labour worker mapped to one project.
class LabourProjectReportRow {
  final String labourName;
  final String skillType;
  final String projectId;
  final String projectName;
  final double dailyWage;

  const LabourProjectReportRow({
    required this.labourName,
    required this.skillType,
    required this.projectId,
    required this.projectName,
    required this.dailyWage,
  });
}

/// Time Period Filter Enum
enum TimePeriod {
  monthly('Monthly', 'monthly'),
  quarterly('Quarterly', 'quarterly'),
  yearly('Yearly', 'yearly');

  final String label;
  final String value;
  const TimePeriod(this.label, this.value);
}
