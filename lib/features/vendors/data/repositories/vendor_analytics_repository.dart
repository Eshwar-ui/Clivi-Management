import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vendor_payment_model.dart';
import '../models/material_issue_model.dart';
import '../models/vendor_summary_models.dart';

class VendorAnalyticsRepository {
  final SupabaseClient _client;

  VendorAnalyticsRepository(this._client);

  /// Get payment summary for all vendors
  Future<List<VendorPaymentSummary>> getVendorPaymentSummaries() async {
    final response = await _client
        .from('vendor_payment_summary')
        .select()
        .order('total_balance', ascending: false);

    return (response)
        .map((json) => VendorPaymentSummary.fromJson(json))
        .toList();
  }

  /// Get payment summary for a specific vendor
  Future<VendorPaymentSummary?> getVendorPaymentSummary(String vendorId) async {
    final response = await _client
        .from('vendor_payment_summary')
        .select()
        .eq('vendor_id', vendorId)
        .single();

    return VendorPaymentSummary.fromJson(response);
  }

  /// Get stock summary for a specific vendor
  Future<List<VendorStockSummary>> getVendorStockSummary(
    String vendorId,
  ) async {
    final response = await _client
        .from('vendor_stock_summary')
        .select()
        .eq('vendor_id', vendorId)
        .order('last_used_at', ascending: false);

    return (response)
        .map((json) => VendorStockSummary.fromJson(json))
        .toList();
  }

  /// Get all vendor stock summaries (for admin overview)
  Future<List<VendorStockSummary>> getAllVendorStockSummaries() async {
    final response = await _client
        .from('vendor_stock_summary')
        .select()
        .order('vendor_name');

    return (response)
        .map((json) => VendorStockSummary.fromJson(json))
        .toList();
  }

  /// Get project inventory summary
  Future<List<ProjectInventorySummary>> getProjectInventorySummary(
    String projectId,
  ) async {
    final response = await _client
        .from('project_inventory_summary')
        .select()
        .eq('project_id', projectId)
        .order('category')
        .order('material_name');

    return (response)
        .map((json) => ProjectInventorySummary.fromJson(json))
        .toList();
  }

  /// Get all projects inventory summary
  Future<List<ProjectInventorySummary>> getAllProjectsInventorySummary() async {
    final response = await _client
        .from('project_inventory_summary')
        .select()
        .order('project_name')
        .order('category');

    return (response)
        .map((json) => ProjectInventorySummary.fromJson(json))
        .toList();
  }

  // ============================================================
  // Vendor material aggregations (new RPCs)
  // ============================================================

  /// Top vendors by total supplied quantity across all projects (admin only)
  Future<List<VendorOverview>> getVendorOverview() async {
    dev.log(
      '[VendorAnalytics] Calling get_vendor_overview RPC...',
      name: 'VendorAnalytics',
    );
    try {
      final response = await _client.rpc('get_vendor_overview');
      final rows = response as List;
      dev.log(
        '[VendorAnalytics] get_vendor_overview SUCCESS: ${rows.length} vendors returned',
        name: 'VendorAnalytics',
      );
      return rows.map((json) => VendorOverview.fromJson(json)).toList();
    } catch (e, st) {
      dev.log(
        '[VendorAnalytics] get_vendor_overview FAILED: $e',
        name: 'VendorAnalytics',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Per-vendor material totals with optional material filter and project scoping
  Future<List<VendorMaterialTotal>> getVendorMaterialTotals({
    required String vendorId,
    String? materialName,
  }) async {
    dev.log(
      '[VendorAnalytics] Calling get_vendor_material_totals RPC for vendor=$vendorId, material=$materialName',
      name: 'VendorAnalytics',
    );
    try {
      final response = await _client.rpc(
        'get_vendor_material_totals',
        params: {
          'p_vendor_id': vendorId,
          if (materialName != null) 'p_material_name': materialName,
        },
      );
      final rows = response as List;
      dev.log(
        '[VendorAnalytics] get_vendor_material_totals SUCCESS: ${rows.length} rows returned',
        name: 'VendorAnalytics',
      );
      for (final row in rows) {
        dev.log('[VendorAnalytics]   row => $row', name: 'VendorAnalytics');
      }
      return rows.map((json) => VendorMaterialTotal.fromJson(json)).toList();
    } catch (e, st) {
      dev.log(
        '[VendorAnalytics] get_vendor_material_totals FAILED: $e',
        name: 'VendorAnalytics',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Aggregated vendor totals for selected tab and date range.
  Future<List<VendorMaterialAggregate>> getMaterialVendorAggregates({
    required MaterialAnalyticsTab tab,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final lines = await _loadInwardSupplyLines(
      tab: tab,
      fromDate: fromDate,
      toDate: toDate,
    );

    final byVendor = <String, _VendorAggregateBuilder>{};
    for (final line in lines) {
      byVendor
          .putIfAbsent(
            line.vendorId,
            () => _VendorAggregateBuilder(
              vendorId: line.vendorId,
              vendorName: line.vendorName,
            ),
          )
          .add(line);
    }

    final result = byVendor.values.map((b) => b.build()).toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return result;
  }

  /// Project totals for a vendor in selected tab/date range.
  Future<List<VendorProjectAggregate>> getVendorProjectAggregates({
    required String vendorId,
    required MaterialAnalyticsTab tab,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final lines = await _loadInwardSupplyLines(
      tab: tab,
      vendorId: vendorId,
      fromDate: fromDate,
      toDate: toDate,
    );

    final byProject = <String, _ProjectAggregateBuilder>{};
    for (final line in lines) {
      byProject
          .putIfAbsent(
            line.projectId,
            () => _ProjectAggregateBuilder(
              vendorId: line.vendorId,
              vendorName: line.vendorName,
              projectId: line.projectId,
              projectName: line.projectName,
            ),
          )
          .add(line);
    }

    final result = byProject.values.map((b) => b.build()).toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return result;
  }

  /// Daily inward logs for a vendor/project in selected tab/date range.
  Future<List<VendorSupplyLine>> getVendorProjectDailyLogs({
    required String vendorId,
    required String projectId,
    required MaterialAnalyticsTab tab,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    return _loadInwardSupplyLines(
      tab: tab,
      vendorId: vendorId,
      projectId: projectId,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  /// Backward-compatible supply lines method.
  Future<List<VendorSupplyLine>> getVendorSupplyLines({
    required String vendorId,
    String? projectId,
    DateTime? fromDate,
    DateTime? toDate,
    MaterialAnalyticsTab? tab,
  }) async {
    final now = DateTime.now();
    final start = fromDate ?? now.subtract(const Duration(days: 7));
    final end = toDate ?? now;
    return _loadInwardSupplyLines(
      vendorId: vendorId,
      projectId: projectId,
      tab: tab,
      fromDate: start,
      toDate: end,
    );
  }

  Future<List<VendorSupplyLine>> _loadInwardSupplyLines({
    String? vendorId,
    String? projectId,
    MaterialAnalyticsTab? tab,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final endOfDay = DateTime(
        toDate.year,
        toDate.month,
        toDate.day,
        23,
        59,
        59,
        999,
      );

      var query = _client
          .from('material_logs')
          .select('''
            supplier_id,
            project_id,
            quantity,
            bill_amount,
            logged_at,
            stock_items!material_logs_item_id_fkey(name, unit, category),
            suppliers!material_logs_supplier_id_fkey(id, name, category),
            projects!material_logs_project_id_fkey(id, name)
          ''')
          .eq('log_type', 'inward')
          .not('supplier_id', 'is', null)
          .gte('logged_at', fromDate.toIso8601String())
          .lte('logged_at', endOfDay.toIso8601String());

      if (vendorId != null) {
        query = query.eq('supplier_id', vendorId);
      }
      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }

      final response = await query.order('logged_at', ascending: false);
      final rows = response as List;
      final result = <VendorSupplyLine>[];

      for (final row in rows) {
        final supplier = row['suppliers'] as Map<String, dynamic>?;
        final stockItem = row['stock_items'] as Map<String, dynamic>?;
        final project = row['projects'] as Map<String, dynamic>?;
        final materialName =
            stockItem?['name'] as String? ?? 'Unknown Material';
        final materialCategory = stockItem?['category'] as String?;
        final supplierCategory = supplier?['category'] as String?;
        final vendorName = supplier?['name'] as String? ?? 'Unknown Vendor';
        final unit = (stockItem?['unit'] as String? ?? 'units').trim();
        final loggedAtStr = row['logged_at'] as String?;
        final loggedAt = loggedAtStr != null && loggedAtStr.isNotEmpty
            ? DateTime.parse(loggedAtStr)
            : DateTime.fromMillisecondsSinceEpoch(0);

        if (tab != null &&
            !_isMaterialMatchForTab(
              tab: tab,
              supplierCategory: supplierCategory,
              stockCategory: materialCategory,
              materialName: materialName,
            )) {
          continue;
        }

        result.add(
          VendorSupplyLine(
            vendorId: row['supplier_id'] as String? ?? '',
            vendorName: vendorName,
            projectId: row['project_id'] as String? ?? '',
            projectName: project?['name'] as String? ?? 'Unknown Project',
            materialName: materialName,
            materialCategory: materialCategory,
            unit: unit.isEmpty ? 'units' : unit,
            quantity: (row['quantity'] as num?)?.toDouble() ?? 0,
            amount: (row['bill_amount'] as num?)?.toDouble() ?? 0,
            loggedAt: loggedAt,
          ),
        );
      }

      if (result.isNotEmpty) {
        return result;
      }

      // Fallback: some environments persist receive entries in
      // material_receipts/material_receipt_items instead of material_logs.
      // Temporarily disabled since the table does not exist and throws 400 Bad Request
      // return _loadReceiptSupplyLines(
      //   vendorId: vendorId,
      //   projectId: projectId,
      //   tab: tab,
      //   fromDate: fromDate,
      //   toDate: toDate,
      // );
      return const [];
    } catch (e, st) {
      dev.log(
        '[VendorAnalytics] _loadInwardSupplyLines FAILED: $e',
        name: 'VendorAnalytics',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  bool _isMaterialMatchForTab({
    required MaterialAnalyticsTab tab,
    required String? supplierCategory,
    required String? stockCategory,
    required String materialName,
  }) {
    final supplierCat = (supplierCategory ?? '').trim().toLowerCase();
    final categorySource = (stockCategory ?? '').trim().toLowerCase();
    final materialSource = materialName.toLowerCase();

    // 1. First, check if the actual material name or its stock category matches any keywords
    final matchesMaterial = tab.keywords.any(
      (kw) => categorySource.contains(kw) || materialSource.contains(kw),
    );

    if (matchesMaterial) {
      return true; // We found the material matches this tab specifically
    }

    // 2. If the material name itself doesn't explicitly match, check if the supplier category matches
    // (e.g. supplier is "Steel", but material was generically named "Rods")
    if (supplierCat.isNotEmpty) {
      final matchesSupplier =
          tab.keywords.any((kw) => supplierCat.contains(kw)) ||
          supplierCat == tab.supplierCategory.toLowerCase();
      if (matchesSupplier) {
        return true;
      }
    }

    return false;
  }

  /// Record a vendor payment
  Future<void> recordPayment({
    required String vendorId,
    String? receiptId,
    required DateTime paymentDate,
    required double paymentAmount,
    String? paymentMethod,
    String? transactionReference,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;

    await _client.from('vendor_payments').insert({
      'vendor_id': vendorId,
      'receipt_id': receiptId,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'payment_amount': paymentAmount,
      'payment_method': paymentMethod,
      'transaction_reference': transactionReference,
      'notes': notes,
      'created_by': userId,
    });

    // Update material_receipts paid_amount if receipt_id is provided
    if (receiptId != null) {
      await _client.rpc(
        'update_receipt_payment',
        params: {'receipt_id': receiptId, 'payment_amt': paymentAmount},
      );
    }
  }

  /// Get payment history for a vendor
  Future<List<VendorPayment>> getVendorPayments(String vendorId) async {
    final response = await _client
        .from('vendor_payments')
        .select()
        .eq('vendor_id', vendorId)
        .order('payment_date', ascending: false);

    return (response)
        .map((json) => VendorPayment.fromJson(json))
        .toList();
  }

  /// Record material issue (outgoing stock)
  Future<void> recordMaterialIssue({
    required String projectId,
    required String issueNumber,
    required DateTime issueDate,
    String? stockItemId,
    required String materialName,
    required double quantity,
    String? unit,
    String? grade,
    String? issuedTo,
    String? purpose,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;

    await _client.from('material_issues').insert({
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
      'created_by': userId,
    });

    // Update stock_items quantity if stock_item_id is provided
    if (stockItemId != null) {
      await _client.rpc(
        'decrease_stock_quantity',
        params: {'stock_id': stockItemId, 'qty': quantity},
      );
    }
  }

  /// Get material issues for a project
  Future<List<MaterialIssue>> getProjectMaterialIssues(String projectId) async {
    final response = await _client
        .from('material_issues')
        .select()
        .eq('project_id', projectId)
        .order('issue_date', ascending: false);

    return (response)
        .map((json) => MaterialIssue.fromJson(json))
        .toList();
  }
}

class _VendorAggregateBuilder {
  final String vendorId;
  final String vendorName;
  final Map<String, double> _quantityByUnit = {};
  final Map<String, _ProjectAmountState> _projectStates = {};
  double _totalAmount = 0;
  DateTime? _lastReceivedAt;

  _VendorAggregateBuilder({required this.vendorId, required this.vendorName});

  void add(VendorSupplyLine line) {
    _quantityByUnit[line.unit] =
        (_quantityByUnit[line.unit] ?? 0) + line.quantity;
    _totalAmount += line.amount;
    _lastReceivedAt = _maxDate(_lastReceivedAt, line.loggedAt);

    final state = _projectStates.putIfAbsent(
      line.projectId,
      () => _ProjectAmountState(projectName: line.projectName),
    );
    state.amount += line.amount;
    state.quantity += line.quantity;
  }

  VendorMaterialAggregate build() {
    String? topProjectId;
    String? topProjectName;
    double maxAmount = -1;
    double maxQuantity = -1;

    _projectStates.forEach((projectId, state) {
      if (state.amount > maxAmount) {
        maxAmount = state.amount;
        topProjectId = projectId;
        topProjectName = state.projectName;
      }
      if (state.amount == 0 && state.quantity > maxQuantity) {
        maxQuantity = state.quantity;
        topProjectId = projectId;
        topProjectName = state.projectName;
      }
    });

    return VendorMaterialAggregate(
      vendorId: vendorId,
      vendorName: vendorName,
      quantityByUnit: Map<String, double>.from(_quantityByUnit),
      totalAmount: _totalAmount,
      topProjectId: topProjectId,
      topProjectName: topProjectName,
      lastReceivedAt: _lastReceivedAt,
    );
  }
}

class _ProjectAggregateBuilder {
  final String vendorId;
  final String vendorName;
  final String projectId;
  final String projectName;
  final Map<String, double> _quantityByUnit = {};
  final List<VendorSupplyLine> _lines = [];
  double _totalAmount = 0;
  DateTime? _lastReceivedAt;

  _ProjectAggregateBuilder({
    required this.vendorId,
    required this.vendorName,
    required this.projectId,
    required this.projectName,
  });

  void add(VendorSupplyLine line) {
    _quantityByUnit[line.unit] =
        (_quantityByUnit[line.unit] ?? 0) + line.quantity;
    _totalAmount += line.amount;
    _lastReceivedAt = _maxDate(_lastReceivedAt, line.loggedAt);
    _lines.add(line);
  }

  VendorProjectAggregate build() {
    _lines.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return VendorProjectAggregate(
      vendorId: vendorId,
      vendorName: vendorName,
      projectId: projectId,
      projectName: projectName,
      quantityByUnit: Map<String, double>.from(_quantityByUnit),
      totalAmount: _totalAmount,
      lastReceivedAt: _lastReceivedAt,
      previewLines: _lines.take(3).toList(),
    );
  }
}

class _ProjectAmountState {
  final String projectName;
  double amount = 0;
  double quantity = 0;

  _ProjectAmountState({required this.projectName});
}

DateTime? _maxDate(DateTime? a, DateTime? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.isAfter(b) ? a : b;
}
