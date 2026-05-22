import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../models/report_models.dart';

/// Repository for Reports and Analytics
class ReportRepository {
  final SupabaseClient _client;

  ReportRepository({SupabaseClient? client}) : _client = client ?? supabase;

  /// Fetch financial metrics for a specific period and optional project
  Future<FinancialStats> getFinancialMetrics({
    required TimePeriod period,
    String? projectId,
  }) async {
    try {
      final response = await _client.rpc(
        'get_financial_metrics',
        params: {'p_period': period.value, 'p_project_id_text': projectId},
      );

      if (response != null) {
        final stats = FinancialStats.fromJson(response as Map<String, dynamic>);
        // If RPC returned real data, use it
        if (stats.totalExpenses > 0 || stats.chartData.isNotEmpty) {
          return stats;
        }
      }

      // Fallback: compute directly from bills table when RPC returns zeros
      return _computeFinancialStatsFromBills(period: period, projectId: projectId);
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch financial metrics: ${e.message}');
      // Try fallback before surfacing error
      try {
        return _computeFinancialStatsFromBills(period: period, projectId: projectId);
      } catch (_) {
        throw DatabaseException.fromPostgrest(e);
      }
    } catch (e) {
      logger.e('Unexpected error fetching financial metrics: $e');
      throw Exception('Failed to load reports: $e');
    }
  }

  /// Fallback: compute FinancialStats by querying bills directly
  Future<FinancialStats> _computeFinancialStatsFromBills({
    required TimePeriod period,
    String? projectId,
  }) async {
    final now = DateTime.now();
    final DateTime startDate;
    switch (period) {
      case TimePeriod.monthly:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case TimePeriod.quarterly:
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case TimePeriod.yearly:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
    }

    var query = _client
        .from('bills')
        .select('amount, bill_type, bill_date, status')
        .gte('bill_date', startDate.toIso8601String().split('T').first)
        .neq('status', 'rejected');

    if (projectId != null) {
      query = query.eq('project_id', projectId);
    }

    final rows = await query;

    double laborCost = 0;
    double materialCost = 0;
    double machineryCost = 0;
    double otherCost = 0;

    for (final row in rows as List) {
      final amount = (row['amount'] as num?)?.toDouble() ?? 0;
      final type = row['bill_type'] as String? ?? '';
      switch (type) {
        case 'workers':
          laborCost += amount;
          break;
        case 'materials':
          materialCost += amount;
          break;
        case 'equipment_rent':
          machineryCost += amount;
          break;
        default:
          otherCost += amount;
      }
    }

    final totalExpenses = laborCost + materialCost + machineryCost + otherCost;

    return FinancialStats(
      totalExpenses: totalExpenses,
      laborCost: laborCost,
      materialCost: materialCost,
      machineryCost: machineryCost,
      otherCost: otherCost,
      growthPercentage: 0,
      chartData: const [],
    );
  }

  /// Material receipts grouped by vendor and project (inward only).
  Future<List<MaterialVendorReportRow>> getMaterialVendorReport({
    String? projectId,
    String? vendorId,
    int limit = 100,
  }) async {
    try {
      var baseQuery = _client
          .from('material_logs')
          .select('''
            quantity,
            logged_at,
            project_id,
            supplier_id,
            stock_items!material_logs_item_id_fkey(name, unit),
            suppliers(name),
            projects(name)
          ''')
          .eq('log_type', 'inward');

      if (projectId != null) {
        baseQuery = baseQuery.eq('project_id', projectId);
      }
      if (vendorId != null) {
        baseQuery = baseQuery.eq('supplier_id', vendorId);
      }

      final rows = await baseQuery
          .order('logged_at', ascending: false)
          .limit(limit);

      // Group client-side by (material, vendor, project)
      final Map<String, MaterialVendorReportRow> grouped = {};
      for (final row in rows as List) {
        final materialName = row['stock_items']['name'] as String? ?? 'Unknown';
        final unit = row['stock_items']['unit'] as String? ?? '';
        final vendorName =
            row['suppliers']?['name'] as String? ?? 'Unknown Vendor';
        final projId = row['project_id'] as String;
        final projName =
            row['projects']?['name'] as String? ?? 'Unknown Project';
        final qty = (row['quantity'] as num?)?.toDouble() ?? 0;
        final loggedAtStr = row['logged_at'] as String?;
        final loggedAt = loggedAtStr != null
            ? DateTime.parse(loggedAtStr)
            : null;

        final key = '$materialName|$vendorName|$projId';
        final existing = grouped[key];
        if (existing == null) {
          grouped[key] = MaterialVendorReportRow(
            materialName: materialName,
            vendorName: vendorName,
            projectId: projId,
            projectName: projName,
            totalReceived: qty,
            unit: unit,
            lastReceivedAt: loggedAt,
          );
        } else {
          grouped[key] = MaterialVendorReportRow(
            materialName: existing.materialName,
            vendorName: existing.vendorName,
            projectId: existing.projectId,
            projectName: existing.projectName,
            totalReceived: existing.totalReceived + qty,
            unit: existing.unit.isNotEmpty ? existing.unit : unit,
            lastReceivedAt: _maxDate(existing.lastReceivedAt, loggedAt),
          );
        }
      }

      return grouped.values.toList()..sort(
        (a, b) => (b.lastReceivedAt ?? DateTime(1970)).compareTo(
          a.lastReceivedAt ?? DateTime(1970),
        ),
      );
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch material vendor report: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      logger.e('Unexpected error fetching material vendor report: $e');
      throw Exception('Failed to load material vendor report: $e');
    }
  }

  /// Machinery usage grouped by machine and project.
  Future<List<MachineryProjectReportRow>> getMachineryProjectReport({
    String? projectId,
    int limit = 200,
  }) async {
    try {
      var baseQuery = _client.from('machinery_logs').select('''
            project_id,
            log_date,
            hours_used,
            machinery:machinery_id(name, type),
            projects(name)
          ''');

      if (projectId != null) {
        baseQuery = baseQuery.eq('project_id', projectId);
      }

      final rows = await baseQuery
          .order('log_date', ascending: false)
          .limit(limit);

      final Map<String, MachineryProjectReportRow> grouped = {};
      for (final row in rows as List) {
        final machineName = row['machinery']?['name'] as String? ?? 'Machine';
        final machineType = row['machinery']?['type'] as String? ?? '';
        final projId = row['project_id'] as String;
        final projName = row['projects']?['name'] as String? ?? 'Project';
        final hrs = (row['hours_used'] as num?)?.toDouble() ?? 0;
        final dateStr = row['log_date'] as String?;
        final loggedAt = dateStr != null ? DateTime.parse(dateStr) : null;

        final key = '$machineName|$projId';
        final existing = grouped[key];
        if (existing == null) {
          grouped[key] = MachineryProjectReportRow(
            machineryName: machineName,
            machineryType: machineType,
            projectId: projId,
            projectName: projName,
            totalHours: hrs,
            lastWorkedAt: loggedAt,
          );
        } else {
          grouped[key] = MachineryProjectReportRow(
            machineryName: existing.machineryName,
            machineryType: existing.machineryType.isNotEmpty
                ? existing.machineryType
                : machineType,
            projectId: existing.projectId,
            projectName: existing.projectName,
            totalHours: existing.totalHours + hrs,
            lastWorkedAt: _maxDate(existing.lastWorkedAt, loggedAt),
          );
        }
      }

      return grouped.values.toList()..sort(
        (a, b) => (b.lastWorkedAt ?? DateTime(1970)).compareTo(
          a.lastWorkedAt ?? DateTime(1970),
        ),
      );
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch machinery report: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      logger.e('Unexpected error fetching machinery report: $e');
      throw Exception('Failed to load machinery report: $e');
    }
  }

  /// Labour mapped to projects (current active workers).
  Future<List<LabourProjectReportRow>> getLabourProjectReport({
    String? projectId,
    int limit = 200,
  }) async {
    try {
      var baseQuery = _client
          .from('labour')
          .select('''
            name,
            skill_type,
            project_id,
            daily_wage,
            projects(name)
          ''')
          .eq('status', 'active');

      if (projectId != null) {
        baseQuery = baseQuery.eq('project_id', projectId);
      }

      final rows = await baseQuery
          .order('created_at', ascending: false)
          .limit(limit);

      return (rows as List).map((row) {
        final projId = row['project_id'] as String? ?? '';
        final projName = row['projects']?['name'] as String? ?? 'Project';
        return LabourProjectReportRow(
          labourName: row['name'] as String? ?? 'Worker',
          skillType: row['skill_type'] as String? ?? 'General',
          projectId: projId,
          projectName: projName,
          dailyWage: (row['daily_wage'] as num?)?.toDouble() ?? 0,
        );
      }).toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch labour report: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    } catch (e) {
      logger.e('Unexpected error fetching labour report: $e');
      throw Exception('Failed to load labour report: $e');
    }
  }

  DateTime? _maxDate(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }
}
