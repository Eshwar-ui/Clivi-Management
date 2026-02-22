import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../models/material_master_model.dart';
import '../models/material_grade_model.dart';

class MaterialMasterRepository {
  final SupabaseClient _client;

  MaterialMasterRepository({SupabaseClient? client})
    : _client = client ?? supabase;

  /// Search material master by name
  Future<List<MaterialMaster>> searchMaterials(String query) async {
    final response = await _client
        .from('material_master')
        .select()
        .ilike('name', '%$query%')
        .limit(10);

    return (response as List).map((e) => MaterialMaster.fromJson(e)).toList();
  }

  /// Get all material masters
  Future<List<MaterialMaster>> getAllMaterials() async {
    final response = await _client
        .from('material_master')
        .select()
        .order('name');

    return (response as List).map((e) => MaterialMaster.fromJson(e)).toList();
  }

  /// Get grades for a specific material ID
  Future<List<MaterialGrade>> getGradesForMaterial(String materialId) async {
    final response = await _client
        .from('material_grades')
        .select()
        .eq('material_id', materialId);

    return (response as List).map((e) => MaterialGrade.fromJson(e)).toList();
  }

  /// Get grades for a specific material NAME (Helper for Stock Item linkage)
  Future<List<MaterialGrade>> getGradesForMaterialName(
    String materialName,
  ) async {
    // 1. Find material ID
    final material = await _client
        .from('material_master')
        .select('id')
        .ilike('name', materialName)
        .limit(1) // Ensure single result
        .maybeSingle();

    if (material == null) return [];

    // 2. Get grades
    return getGradesForMaterial(material['id'] as String);
  }

  /// Add new material master (idempotent get-or-create)
  Future<MaterialMaster> addMaterialMaster(String name) async {
    // 1. Check if exists
    final existing = await _client
        .from('material_master')
        .select()
        .ilike('name', name)
        .limit(1) // Ensure single result
        .maybeSingle();

    if (existing != null) {
      return MaterialMaster.fromJson(existing);
    }

    try {
      final response = await _client
          .from('material_master')
          .insert({'name': name})
          .select()
          .single();
      return MaterialMaster.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique violation
        final retry = await _client
            .from('material_master')
            .select()
            .eq('name', name)
            .single();
        return MaterialMaster.fromJson(retry);
      }
      rethrow;
    }
  }

  /// Add new grade (handles 409 conflicts with generated grade_key)
  Future<Map<String, dynamic>> addMaterialGrade({
    required String materialId,
    required String gradeName,
  }) async {
    final normalized = gradeName.trim();

    try {
      // Try insert first
      final row = await _client
          .from('material_grades')
          .insert({'material_id': materialId, 'grade_name': normalized})
          .select()
          .single();
      return row;
    } on PostgrestException catch (e) {
      // Handle 409 conflict (23505 = unique violation)
      if (e.code == '23505') {
        // Grade already exists, fetch and return it
        final existing = await _client
            .from('material_grades')
            .select()
            .eq('material_id', materialId)
            .ilike('grade_name', normalized)
            .single();
        return existing;
      }
      rethrow;
    }
  }
}
