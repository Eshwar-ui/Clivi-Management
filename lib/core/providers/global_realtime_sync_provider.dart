import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/auth_repository_provider.dart';
import '../../features/bills/providers/bill_provider.dart' as bills;
import '../../features/blueprints/providers/blueprints_provider.dart'
    as blueprints;
import '../../features/dashboard/providers/dashboard_provider.dart'
    as dashboard;
import '../../features/inventory/providers/inventory_provider.dart'
    as inventory;
import '../../features/labour/providers/labour_provider.dart' as labour;
import '../../features/machinery/providers/machinery_provider.dart'
    as machinery;
import '../../features/materials/providers/master_data_provider.dart'
    as material_master;
import '../../features/materials/providers/repository_providers.dart';
import '../../features/materials/providers/receipts_provider.dart' as receipts;
import '../../features/materials/providers/stock_provider.dart'
    as materials_stock;
import '../../features/projects/providers/project_provider.dart' as projects;
import '../../features/reports/providers/report_provider.dart' as reports;
import '../../features/vendors/providers/vendor_analytics_provider.dart'
    as vendors;
import '../config/supabase_client.dart';

final globalRealtimeSyncProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return;
  }

  final pendingTables = <String>{};
  Timer? debounce;

  void flush() {
    if (pendingTables.isEmpty) return;

    final tables = pendingTables.toSet();
    pendingTables.clear();

    _invalidateForTables(ref, tables);

    logger.i('Realtime sync refresh triggered for: ${tables.toList()..sort()}');
  }

  void scheduleRefresh(String table) {
    pendingTables.add(table);
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 300), flush);
  }

  final channel = supabase.channel(
    'global_realtime_sync_${user.id.substring(0, 6)}',
    opts: const RealtimeChannelConfig(ack: true),
  );

  for (final table in _watchedTables) {
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      callback: (_) => scheduleRefresh(table),
    );
  }

  channel.subscribe((status, error) {
    if (status == RealtimeSubscribeStatus.subscribed) {
      logger.i('Global realtime sync subscribed');
      return;
    }

    if (status == RealtimeSubscribeStatus.channelError ||
        status == RealtimeSubscribeStatus.timedOut ||
        status == RealtimeSubscribeStatus.closed) {
      logger.w(
        'Global realtime sync issue ($status): ${error?.toString() ?? 'no details'}',
      );
    }
  });

  ref.onDispose(() {
    debounce?.cancel();
    channel.unsubscribe();
  });
});

const Set<String> _watchedTables = {
  'projects',
  'project_assignments',
  'bills',
  'stock_items',
  'material_logs',
  'suppliers',
  'material_master',
  'material_grades',
  'material_issues',
  'vendor_payments',
  'vendor_payment_summary',
  'vendor_stock_summary',
  'project_inventory_summary',
  'machinery',
  'machinery_logs',
  'labour',
  'labour_attendance',
  'daily_labour_logs',
  'blueprints',
  'operation_logs',
  'user_profiles',
};

const Set<String> _projectTables = {'projects', 'project_assignments'};
const Set<String> _billTables = {'bills'};
const Set<String> _materialTables = {
  'stock_items',
  'material_logs',
  'suppliers',
  'material_receipts',
  'material_receipt_items',
  'material_master',
  'material_grades',
  'material_issues',
  'vendor_payments',
  'vendor_payment_summary',
  'vendor_stock_summary',
  'project_inventory_summary',
};
const Set<String> _machineryTables = {'machinery', 'machinery_logs'};
const Set<String> _labourTables = {
  'labour',
  'labour_attendance',
  'daily_labour_logs',
};
const Set<String> _blueprintTables = {'blueprints'};
const Set<String> _activityTables = {'operation_logs'};
const Set<String> _userTables = {'user_profiles'};

void _invalidateForTables(Ref ref, Set<String> tables) {
  if (tables.any(_projectTables.contains)) {
    _invalidateProjectDomain(ref);
  }

  if (tables.any(_billTables.contains)) {
    _invalidateBillDomain(ref);
  }

  if (tables.any(_materialTables.contains)) {
    _invalidateMaterialDomain(ref);
  }

  if (tables.any(_machineryTables.contains)) {
    _invalidateMachineryDomain(ref);
  }

  if (tables.any(_labourTables.contains)) {
    _invalidateLabourDomain(ref);
  }

  if (tables.any(_blueprintTables.contains)) {
    _invalidateBlueprintDomain(ref);
  }

  if (tables.any(_activityTables.contains)) {
    _invalidateDashboardDomain(ref);
  }

  if (tables.any(_userTables.contains)) {
    _invalidateUsersDomain(ref);
  }
}

void _invalidateProjectDomain(Ref ref) {
  ref.invalidate(projects.projectRepositoryProvider);
  ref.invalidate(projects.projectListProvider);
  ref.invalidate(projects.projectDetailProvider);
  ref.invalidate(projects.siteManagerSelectionProvider);

  // Project changes affect dashboard, reports and analytics.
  _invalidateDashboardDomain(ref);
  _invalidateReportDomain(ref);
  ref.invalidate(vendors.vendorAnalyticsRepositoryProvider);
  ref.invalidate(vendors.vendorOverviewProvider);
}

void _invalidateBillDomain(Ref ref) {
  ref.invalidate(bills.billRepositoryProvider);
  ref.invalidate(bills.billsProvider);
  ref.invalidate(bills.billsCombinedProvider);
  ref.invalidate(bills.dashboardBillsProvider);
  ref.invalidate(bills.dashboardBillsCombinedProvider);
  ref.invalidate(bills.paginatedPendingBillsProvider);

  _invalidateDashboardDomain(ref);
  _invalidateReportDomain(ref);
}

void _invalidateMaterialDomain(Ref ref) {
  ref.invalidate(inventory.inventoryRepositoryProvider);
  ref.invalidate(materials_stock.stockRepositoryProvider);
  ref.invalidate(materialsRepositoryProvider);
  ref.invalidate(receiptsRepositoryProvider);
  ref.invalidate(material_master.materialMasterRepositoryProvider);
  ref.invalidate(vendors.vendorAnalyticsRepositoryProvider);

  // Key projections and reports that depend on material movement.
  ref.invalidate(inventory.stockItemsProvider);
  ref.invalidate(inventory.materialLogsProvider);
  ref.invalidate(inventory.inwardLogsProvider);
  ref.invalidate(inventory.outwardLogsProvider);
  ref.invalidate(inventory.lowStockItemsProvider);
  ref.invalidate(inventory.suppliersProvider);
  ref.invalidate(materials_stock.materialLogsProvider);
  ref.invalidate(materials_stock.stockItemsStreamProvider);
  ref.invalidate(receipts.projectReceiptsProvider);
  ref.invalidate(receipts.projectStockBalanceProvider);

  ref.invalidate(vendors.materialVendorAggregatesProvider);
  ref.invalidate(vendors.vendorProjectAggregatesProvider);
  ref.invalidate(vendors.vendorProjectDailyLogsProvider);
  ref.invalidate(vendors.vendorSupplyLinesProvider);
  ref.invalidate(vendors.vendorSupplyLinesFilteredProvider);
  ref.invalidate(vendors.vendorMaterialTotalsProvider);

  _invalidateReportDomain(ref);
  _invalidateDashboardDomain(ref);
}

void _invalidateMachineryDomain(Ref ref) {
  ref.invalidate(machinery.machineryRepositoryProvider);
  ref.invalidate(machinery.machineryListProvider);
  ref.invalidate(machinery.machineryLogsProvider);

  _invalidateReportDomain(ref);
  _invalidateDashboardDomain(ref);
}

void _invalidateLabourDomain(Ref ref) {
  ref.invalidate(labour.labourRepositoryProvider);
  ref.invalidate(labour.projectLabourProvider);
  ref.invalidate(labour.activeLabourProvider);
  ref.invalidate(labour.masterLabourProvider);
  ref.invalidate(labour.attendanceByDateProvider);
  ref.invalidate(labour.labourWithAttendanceProvider);
  ref.invalidate(labour.todayAttendanceSummaryProvider);

  _invalidateReportDomain(ref);
  _invalidateDashboardDomain(ref);
}

void _invalidateBlueprintDomain(Ref ref) {
  ref.invalidate(blueprints.blueprintRepositoryProvider);
  ref.invalidate(blueprints.blueprintFoldersProvider);
  ref.invalidate(blueprints.blueprintFilesProvider);
  ref.invalidate(blueprints.allBlueprintsProvider);

  _invalidateDashboardDomain(ref);
}

void _invalidateDashboardDomain(Ref ref) {
  ref.invalidate(dashboard.dashboardRepositoryProvider);
  ref.invalidate(dashboard.dashboardStatsProvider);
  ref.invalidate(dashboard.recentActivityProvider);
  ref.invalidate(dashboard.activeProjectsProvider);
}

void _invalidateReportDomain(Ref ref) {
  ref.invalidate(reports.reportRepositoryProvider);
  ref.invalidate(reports.reportProvider);
}

void _invalidateUsersDomain(Ref ref) {
  // Refresh user-driven lists (site manager directories, assignee dropdowns).
  ref.invalidate(authRepositoryProvider);
  ref.invalidate(projects.projectRepositoryProvider);
}
