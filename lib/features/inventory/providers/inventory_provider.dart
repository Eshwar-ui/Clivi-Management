import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/stock_item_model.dart';
import '../data/models/material_log_model.dart';
import '../data/models/supplier_model.dart';
import '../data/repositories/inventory_repository.dart';

/// Provider for inventory repository
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
});

/// Provider for stock items of a project
final stockItemsProvider = FutureProvider.family<List<StockItemModel>, String>((
  ref,
  projectId,
) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getStockItems(projectId);
});

/// Provider for material logs of a project
final materialLogsProvider =
    FutureProvider.family<List<MaterialLogModel>, String>((
      ref,
      projectId,
    ) async {
      final repository = ref.watch(inventoryRepositoryProvider);
      return repository.getMaterialLogs(projectId);
    });

/// Provider for inward logs only
final inwardLogsProvider =
    FutureProvider.family<List<MaterialLogModel>, String>((
      ref,
      projectId,
    ) async {
      final repository = ref.watch(inventoryRepositoryProvider);
      return repository.getMaterialLogs(projectId, type: LogType.inward);
    });

/// Provider for outward logs only
final outwardLogsProvider =
    FutureProvider.family<List<MaterialLogModel>, String>((
      ref,
      projectId,
    ) async {
      final repository = ref.watch(inventoryRepositoryProvider);
      return repository.getMaterialLogs(projectId, type: LogType.outward);
    });

/// Provider for low stock alerts
final lowStockItemsProvider =
    FutureProvider.family<List<StockItemModel>, String>((ref, projectId) async {
      final repository = ref.watch(inventoryRepositoryProvider);
      return repository.getLowStockItems(projectId);
    });

/// Provider for all active suppliers
final suppliersProvider = FutureProvider<List<SupplierModel>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getSuppliers();
});
