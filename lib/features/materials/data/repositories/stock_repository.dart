import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/validators.dart';
import '../models/stock_item.dart';
import '../models/material_log.dart';
import '../../../../features/inventory/data/models/supplier_model.dart';

class StockRepository {
  final SupabaseClient _client;

  StockRepository(this._client);

  /// Gets stock items for a SPECIFIC project
  Future<List<StockItem>> getStockItemsByProject(String projectId) async {
    validateProjectId(projectId);
    final response = await _client
        .from('stock_items')
        .select('*')
        .eq('project_id', projectId) // 👈 FILTER BY PROJECT
        .order('name', ascending: true);

    return (response as List).map((json) => StockItem.fromJson(json)).toList();
  }

  /// Get material logs for a specific project
  Future<List<MaterialLog>> getMaterialLogsByProject(String projectId) async {
    validateProjectId(projectId);
    if (projectId.isEmpty) {
      throw ArgumentError('projectId is required to fetch material logs.');
    }

    final response = await _client
        .from('material_logs')
        .select('''
          *,
          stock_item:stock_items!material_logs_item_id_fkey(id, name, unit),
          supplier:suppliers(id, name)
        ''')
        .eq('project_id', projectId) // ensure per-project isolation
        .order('logged_at', ascending: false);

    return (response as List)
        .map((json) => MaterialLog.fromJson(json))
        .toList();
  }

  /// Get Suppliers for a SPECIFIC project
  Future<List<SupplierModel>> getProjectSuppliers(String projectId) async {
    validateProjectId(projectId);
    final response = await _client
        .from('suppliers')
        .select()
        .eq('project_id', projectId)
        .eq('is_active', true)
        .order('name', ascending: true);

    return (response as List).map((e) => SupplierModel.fromJson(e)).toList();
  }

  /// Add a new Supplier for a SPECIFIC project
  Future<SupplierModel> addProjectSupplier(
    String projectId,
    String name,
  ) async {
    validateProjectId(projectId);
    // 1. Check existing in this project
    final existing = await _client
        .from('suppliers')
        .select()
        .eq('project_id', projectId)
        .ilike('name', name)
        .maybeSingle();

    if (existing != null) {
      return SupplierModel.fromJson(existing);
    }

    // 2. Create new
    final response = await _client
        .from('suppliers')
        .insert({
          'project_id': projectId,
          'name': name,
          'is_active': true,
          'created_by': _client.auth.currentUser?.id,
        })
        .select()
        .single();

    return SupplierModel.fromJson(response);
  }

  /// Ensure a Stock Item exists for this project (Get or Create)
  Future<StockItem> getOrCreateStockItem({
    required String projectId,
    required String name,
    String? grade,
    required String unit,
  }) async {
    validateProjectId(projectId);

    final normalizedName = name.trim();
    final normalizedGrade = (grade ?? '').trim();

    // 1. Check specific match (Name + Grade) for this project
    var query = _client
        .from('stock_items')
        .select()
        .eq('project_id', projectId)
        .ilike('name', normalizedName)
        .eq('grade', normalizedGrade);

    final existing = await query.maybeSingle();

    if (existing != null) {
      return StockItem.fromJson(existing);
    }

    final userId = _client.auth.currentUser?.id;

    // 2. Insert new Stock Item
    final response = await _client
        .from('stock_items')
        .insert({
          'project_id': projectId,
          'name': normalizedName,
          'grade': normalizedGrade,
          'unit': unit,
          'quantity': 0,
          'created_by': userId,
        })
        .select()
        .single();

    return StockItem.fromJson(response);
  }

  /// Log material inward (received) - Uses Transactional RPC
  Future<void> logMaterialInward({
    required String projectId,
    required String stockItemName,
    required String stockItemUnit,
    String? stockItemGrade,
    required String supplierId,
    required double quantity,
    required double billAmount,
    required String paymentType,
    String? activity,
    String? notes,
  }) async {
    validateProjectId(projectId);
    if (supplierId.isEmpty) {
      throw Exception('Supplier ID is required. Vendor must be selected.');
    }

    final params = {
      'p_project_id': projectId,
      'p_material_name': stockItemName,
      'p_grade': stockItemGrade, // Can be null - RPC handles it
      'p_unit': stockItemUnit,
      'p_quantity': quantity,
      'p_supplier_id': supplierId,
      'p_bill_amount': billAmount,
      'p_payment_type': paymentType,
      'p_activity': activity ?? 'Material Received',
      'p_notes': notes,
    };

    await _client.rpc('receive_material', params: params);
  }

  /// Log material outward (consumed)
  Future<void> logMaterialOutward({
    required String projectId,
    required String itemId,
    required double quantity,
    String? activity,
    String? notes,
  }) async {
    validateProjectId(projectId);
    final userId = _client.auth.currentUser?.id;

    // Insert outward log - Trigger will validate sufficient stock
    await _client.from('material_logs').insert({
      'project_id': projectId,
      'item_id': itemId,
      'log_type': 'outward',
      'quantity': quantity,
      'activity': activity ?? 'Material Consumed',
      'notes': notes,
      'logged_by': userId,
      'logged_at': DateTime.now().toIso8601String(),
    });
  }

  /// Stream stock items (using dynamic view if possible, or table)
  Stream<List<StockItem>> streamStockItemsByProject(String projectId) {
    validateProjectId(projectId);
    return _client
        .from('stock_items')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => StockItem.fromJson(json)).toList());
  }

  /// Fetch Dynamic Balance
  Future<List<Map<String, dynamic>>> getStockBalance(String projectId) async {
    validateProjectId(projectId);
    final response = await _client
        .from('v_stock_balance_dynamic')
        .select()
        .eq('project_id', projectId)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }
}
