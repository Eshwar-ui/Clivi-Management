import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/vendor_analytics_repository.dart';
import '../data/models/vendor_summary_models.dart';

// Repository Provider
final vendorAnalyticsRepositoryProvider = Provider<VendorAnalyticsRepository>((
  ref,
) {
  final supabase = Supabase.instance.client;
  return VendorAnalyticsRepository(supabase);
});

// Vendor Payment Summaries Provider
final vendorPaymentSummariesProvider =
    FutureProvider<List<VendorPaymentSummary>>((ref) async {
      final repo = ref.watch(vendorAnalyticsRepositoryProvider);
      return repo.getVendorPaymentSummaries();
    });

// Specific Vendor Payment Summary Provider
final vendorPaymentSummaryProvider =
    FutureProvider.family<VendorPaymentSummary?, String>((ref, vendorId) async {
      final repo = ref.watch(vendorAnalyticsRepositoryProvider);
      return repo.getVendorPaymentSummary(vendorId);
    });

// Vendor Stock Summary Provider
final vendorStockSummaryProvider =
    FutureProvider.family<List<VendorStockSummary>, String>((
      ref,
      vendorId,
    ) async {
      final repo = ref.watch(vendorAnalyticsRepositoryProvider);
      return repo.getVendorStockSummary(vendorId);
    });

// All Vendor Stock Summaries Provider
final allVendorStockSummariesProvider =
    FutureProvider<List<VendorStockSummary>>((ref) async {
      final repo = ref.watch(vendorAnalyticsRepositoryProvider);
      return repo.getAllVendorStockSummaries();
    });

// Project Inventory Summary Provider
final projectInventorySummaryProvider =
    FutureProvider.family<List<ProjectInventorySummary>, String>((
      ref,
      projectId,
    ) async {
      final repo = ref.watch(vendorAnalyticsRepositoryProvider);
      return repo.getProjectInventorySummary(projectId);
    });

// All Projects Inventory Summary Provider
final allProjectsInventorySummaryProvider =
    FutureProvider<List<ProjectInventorySummary>>((ref) async {
      final repo = ref.watch(vendorAnalyticsRepositoryProvider);
      return repo.getAllProjectsInventorySummary();
    });

// Top vendors across all projects (admin only)
final vendorOverviewProvider = FutureProvider<List<VendorOverview>>((
  ref,
) async {
  final repo = ref.watch(vendorAnalyticsRepositoryProvider);
  return repo.getVendorOverview();
});

final materialAnalyticsTabProvider = StateProvider<MaterialAnalyticsTab>(
  (ref) => MaterialAnalyticsTab.steel,
);

final vendorChartMetricProvider = StateProvider<VendorChartMetric>(
  (ref) => VendorChartMetric.quantity,
);

final vendorAnalyticsDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
});

class MaterialVendorAggregatesRequest {
  final MaterialAnalyticsTab tab;
  final DateTime fromDate;
  final DateTime toDate;

  const MaterialVendorAggregatesRequest({
    required this.tab,
    required this.fromDate,
    required this.toDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialVendorAggregatesRequest &&
          runtimeType == other.runtimeType &&
          tab == other.tab &&
          fromDate == other.fromDate &&
          toDate == other.toDate;

  @override
  int get hashCode => Object.hash(tab, fromDate, toDate);
}

final materialVendorAggregatesProvider =
    FutureProvider.family<
      List<VendorMaterialAggregate>,
      MaterialVendorAggregatesRequest
    >((ref, req) async {
      final repo = ref.watch(vendorAnalyticsRepositoryProvider);
      return repo.getMaterialVendorAggregates(
        tab: req.tab,
        fromDate: req.fromDate,
        toDate: req.toDate,
      );
    });

class VendorProjectAggregatesRequest {
  final String vendorId;
  final MaterialAnalyticsTab tab;
  final DateTime fromDate;
  final DateTime toDate;

  const VendorProjectAggregatesRequest({
    required this.vendorId,
    required this.tab,
    required this.fromDate,
    required this.toDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorProjectAggregatesRequest &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          tab == other.tab &&
          fromDate == other.fromDate &&
          toDate == other.toDate;

  @override
  int get hashCode => Object.hash(vendorId, tab, fromDate, toDate);
}

final vendorProjectAggregatesProvider =
    FutureProvider.family<
      List<VendorProjectAggregate>,
      VendorProjectAggregatesRequest
    >((ref, req) async {
      final repo = ref.watch(vendorAnalyticsRepositoryProvider);
      return repo.getVendorProjectAggregates(
        vendorId: req.vendorId,
        tab: req.tab,
        fromDate: req.fromDate,
        toDate: req.toDate,
      );
    });

class VendorProjectDailyLogsRequest {
  final String vendorId;
  final String projectId;
  final MaterialAnalyticsTab tab;
  final DateTime fromDate;
  final DateTime toDate;

  const VendorProjectDailyLogsRequest({
    required this.vendorId,
    required this.projectId,
    required this.tab,
    required this.fromDate,
    required this.toDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorProjectDailyLogsRequest &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          projectId == other.projectId &&
          tab == other.tab &&
          fromDate == other.fromDate &&
          toDate == other.toDate;

  @override
  int get hashCode => Object.hash(vendorId, projectId, tab, fromDate, toDate);
}

final vendorProjectDailyLogsProvider =
    FutureProvider.family<
      List<VendorSupplyLine>,
      VendorProjectDailyLogsRequest
    >((ref, req) async {
      final repo = ref.watch(vendorAnalyticsRepositoryProvider);
      return repo.getVendorProjectDailyLogs(
        vendorId: req.vendorId,
        projectId: req.projectId,
        tab: req.tab,
        fromDate: req.fromDate,
        toDate: req.toDate,
      );
    });

// Vendor material totals with optional material filter
class VendorTotalsRequest {
  final String vendorId;
  final String? materialName;
  const VendorTotalsRequest(this.vendorId, {this.materialName});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorTotalsRequest &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          materialName == other.materialName;

  @override
  int get hashCode => vendorId.hashCode ^ (materialName?.hashCode ?? 0);
}

final vendorMaterialTotalsProvider =
    FutureProvider.family<List<VendorMaterialTotal>, VendorTotalsRequest>((
      ref,
      request,
    ) async {
      final repo = ref.watch(vendorAnalyticsRepositoryProvider);
      return repo.getVendorMaterialTotals(
        vendorId: request.vendorId,
        materialName: request.materialName,
      );
    });

class VendorSupplyFilterRequest {
  final String vendorId;
  final String? projectId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final MaterialAnalyticsTab? tab;

  const VendorSupplyFilterRequest({
    required this.vendorId,
    this.projectId,
    this.fromDate,
    this.toDate,
    this.tab,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorSupplyFilterRequest &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          projectId == other.projectId &&
          fromDate == other.fromDate &&
          toDate == other.toDate &&
          tab == other.tab;

  @override
  int get hashCode =>
      vendorId.hashCode ^
      (projectId?.hashCode ?? 0) ^
      (fromDate?.hashCode ?? 0) ^
      (toDate?.hashCode ?? 0) ^
      (tab?.hashCode ?? 0);
}

final vendorSupplyLinesProvider =
    FutureProvider.family<List<VendorSupplyLine>, String>((
      ref,
      vendorId,
    ) async {
      final repo = ref.watch(vendorAnalyticsRepositoryProvider);
      return repo.getVendorSupplyLines(vendorId: vendorId);
    });

final vendorSupplyLinesFilteredProvider =
    FutureProvider.family<List<VendorSupplyLine>, VendorSupplyFilterRequest>((
      ref,
      request,
    ) async {
      final repo = ref.watch(vendorAnalyticsRepositoryProvider);
      return repo.getVendorSupplyLines(
        vendorId: request.vendorId,
        projectId: request.projectId,
        fromDate: request.fromDate,
        toDate: request.toDate,
        tab: request.tab,
      );
    });
