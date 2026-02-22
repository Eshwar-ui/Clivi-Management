import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../models/stock_item_model.dart';
import '../models/material_log_model.dart';
import '../models/supplier_model.dart';

/// Repository for inventory-related operations
class InventoryRepository {
  final SupabaseClient _client;

  InventoryRepository({SupabaseClient? client}) : _client = client ?? supabase;

  // ============================================================
  // STOCK ITEMS CRUD
  // ============================================================

  /// Get all stock items for a project
  Future<List<StockItemModel>> getStockItems(String projectId) async {
    try {
      final response = await _client
          .from('stock_items')
          .select()
          .eq('project_id', projectId)
          .order('name');

      return (response as List)
          .map((json) => StockItemModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch stock items: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Add a new stock item
  Future<StockItemModel> addStockItem(StockItemModel item) async {
    try {
      final response = await _client
          .from('stock_items')
          .insert(item.toJson())
          .select()
          .single();

      return StockItemModel.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('Failed to add stock item: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Update stock item quantity
  Future<void> updateStockQuantity(String itemId, double newQuantity) async {
    try {
      await _client
          .from('stock_items')
          .update({'quantity': newQuantity})
          .eq('id', itemId);
    } on PostgrestException catch (e) {
      logger.e('Failed to update stock quantity: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Delete stock item
  Future<void> deleteStockItem(String itemId) async {
    try {
      await _client.from('stock_items').delete().eq('id', itemId);
    } on PostgrestException catch (e) {
      logger.e('Failed to delete stock item: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  // ============================================================
  // MATERIAL LOGS CRUD
  // ============================================================

  /// Get material logs for a project
  Future<List<MaterialLogModel>> getMaterialLogs(
    String projectId, {
    LogType? type,
    int limit = 50,
  }) async {
    if (projectId.isEmpty) {
      throw ArgumentError('projectId is required to fetch material logs.');
    }

    try {
      var query = _client
          .from('material_logs')
          .select('''
            *,
            stock_items(name, unit),
            suppliers(name)
          ''')
          .eq('project_id', projectId); // enforce per-project isolation

      if (type != null) {
        query = query.eq('log_type', type.value);
      }

      final response = await query
          .order('logged_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => MaterialLogModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch material logs: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Add a material log entry and update stock quantity.
  /// Optionally creates a bill for inward (received) logs when payment data is provided.
  Future<MaterialLogModel> addMaterialLog(
    MaterialLogModel log, {
    String? paymentType,
    double? billAmount,
    String? billTitle,
  }) async {
    try {
      // 1. Insert the log entry
      final response = await _client
          .from('material_logs')
          .insert(log.toInsertJson())
          .select('''
            *,
            stock_items(name, unit),
            suppliers(name)
          ''')
          .single();

      // 2. Update stock quantity based on log type
      final stockItem = await _client
          .from('stock_items')
          .select('quantity')
          .eq('id', log.itemId)
          .single();

      final currentQty = double.tryParse(stockItem['quantity'].toString()) ?? 0;
      double newQty;

      if (log.logType == LogType.inward) {
        newQty = currentQty + log.quantity;
      } else {
        newQty = currentQty - log.quantity;
        if (newQty < 0) newQty = 0;
      }

      await _client
          .from('stock_items')
          .update({'quantity': newQty})
          .eq('id', log.itemId);

      // 3. (Optional) Create bill for received materials
      final shouldCreateBill =
          log.logType == LogType.inward &&
          billAmount != null &&
          paymentType != null;
      if (shouldCreateBill) {
        await _client.from('bills').insert({
          'project_id': log.projectId,
          'title': billTitle ?? 'Material Purchase',
          'bill_type': 'materials',
          'amount': billAmount,
          'payment_type': paymentType,
          'status': 'pending',
          'created_by': _client.auth.currentUser?.id,
          'bill_date': DateTime.now().toIso8601String(),
        });
      }

      logger.i(
        'Material log added: ${log.logType.displayName} ${log.quantity}',
      );
      return MaterialLogModel.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('Failed to add material log: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Get low stock items for a project
  Future<List<StockItemModel>> getLowStockItems(String projectId) async {
    try {
      final response = await _client
          .from('stock_items')
          .select()
          .eq('project_id', projectId)
          .lte('quantity', _client.rpc('get_low_stock_threshold'))
          .order('quantity');

      // Filter client-side for proper low stock detection
      final items = (response as List)
          .map((json) => StockItemModel.fromJson(json))
          .where((item) => item.isLowStock)
          .toList();

      return items;
    } catch (e) {
      // Fallback: get all and filter
      final allItems = await getStockItems(projectId);
      return allItems.where((item) => item.isLowStock).toList();
    }
  }

  // ============================================================
  // SUPPLIER CRUD
  // ============================================================

  /// Get all suppliers
  Future<List<SupplierModel>> getSuppliers({bool activeOnly = true}) async {
    try {
      final query = activeOnly
          ? _client
                .from('suppliers')
                .select()
                .eq('is_active', true)
                .order('name')
          : _client.from('suppliers').select().order('name');
      final response = await query;
      return (response as List)
          .map((json) => SupplierModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch suppliers: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Add a new supplier
  Future<SupplierModel> addSupplier(SupplierModel supplier) async {
    try {
      final response = await _client
          .from('suppliers')
          .insert(supplier.toJson())
          .select()
          .single();
      return SupplierModel.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('Failed to add supplier: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Update a supplier
  Future<void> updateSupplier(
    String supplierId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _client.from('suppliers').update(data).eq('id', supplierId);
    } on PostgrestException catch (e) {
      logger.e('Failed to update supplier: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Delete a material log (with optional note for audit)
  Future<void> deleteMaterialLog({
    required String logId,
    required String projectId,
    String? note,
    String? actorRole,
  }) async {
    await _client.from('material_logs').delete().eq('id', logId);

    // Log operation for admins
    await _client.rpc(
      'log_operation',
      params: {
        'p_operation_type': 'delete',
        'p_entity_type': 'stock',
        'p_entity_id': logId,
        'p_title': '[DELETE] Material log',
        'p_description': note ?? '',
        'p_project_id': projectId,
      },
    );
  }

  /// Delete a supplier (soft delete by setting is_active = false)
  Future<void> deleteSupplier(String supplierId) async {
    try {
      await _client
          .from('suppliers')
          .update({'is_active': false})
          .eq('id', supplierId);
    } on PostgrestException catch (e) {
      logger.e('Failed to delete supplier: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Soft delete ALL suppliers (used for admin bulk cleanup)
  Future<void> deleteAllSuppliers() async {
    try {
      await _client.from('suppliers').update({'is_active': false});
    } on PostgrestException catch (e) {
      logger.e('Failed to bulk delete suppliers: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }
}
