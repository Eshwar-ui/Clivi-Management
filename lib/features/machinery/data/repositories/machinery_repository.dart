import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/machinery_model.dart';
import '../models/machinery_log_model.dart';

class MachineryRepository {
  final SupabaseClient _client;

  MachineryRepository(this._client);

  /// Get machinery logs for a specific project
  Future<List<MachineryLog>> getMachineryLogsByProject(String projectId) async {
    final response = await _client
        .from('machinery_logs')
        .select('''
          *,
          machinery (id, name, type, registration_no)
        ''')
        .eq('project_id', projectId) // 👈 FILTER BY PROJECT
        .order('logged_at', ascending: false);

    return (response as List)
        .map((json) => MachineryLog.fromJson(json))
        .toList();
  }

  /// Get ALL machinery (to select for logging)
  Future<List<MachineryModel>> getAllMachinery() async {
    final response = await _client.from('machinery').select('*').order('name');

    return (response as List)
        .map((json) => MachineryModel.fromJson(json))
        .toList();
  }

  /// Create new machinery (Master)
  Future<void> createMachinery({
    required String name,
    required String type,
    String? registrationNo,
    required String ownershipType, // 'Own' or 'Rental'
    String status = 'available', // ✅ Matches DB constraint
  }) async {
    await _client.from('machinery').insert({
      'name': name,
      'type': type,
      'registration_no': registrationNo,
      'ownership_type': ownershipType,
      'status': status,
      'created_by': _client.auth.currentUser?.id,
    });
  }

  Future<void> updateMachinery({
    required String machineryId,
    required Map<String, dynamic> data,
  }) async {
    await _client.from('machinery').update(data).eq('id', machineryId);
  }

  Future<void> deleteMachinery(String machineryId) async {
    await _client.from('machinery').delete().eq('id', machineryId);
  }

  Future<void> deleteAllMachinery() async {
    await _client.from('machinery').delete();
  }

  /// Log machinery usage (Time Based)
  Future<void> logMachineryUsageTimeBased({
    required String projectId,
    required String machineryId,
    required String workActivity,
    required DateTime logDate,
    required String startTime, // HH:mm
    required String endTime, // HH:mm
    required double totalHours,
    String? notes,
  }) async {
    await _client.from('machinery_logs').insert({
      'project_id': projectId,
      'machinery_id': machineryId,
      'log_type': 'usage',
      'work_activity': workActivity,
      'log_date': logDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'hours_used': totalHours,
      'notes': notes,
      'logged_by': _client.auth.currentUser?.id,
      'logged_at': DateTime.now().toIso8601String(),
    });

    // Update machinery total hours
    await _client.rpc(
      'increment_machinery_hours',
      params: {'p_machinery_id': machineryId, 'p_hours': totalHours},
    );
  }

  /// Log machinery usage (Legacy / Reading Based)
  Future<void> logMachineryUsage({
    required String projectId,
    required String machineryId,
    required String workActivity,
    required DateTime logDate,
    required double startReading,
    required double endReading,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final executionHours = endReading - startReading;

    // Insert log
    await _client.from('machinery_logs').insert({
      'project_id': projectId,
      'machinery_id': machineryId,
      'work_activity': workActivity,
      'log_date': logDate.toIso8601String().split('T')[0],
      'start_reading': startReading,
      'end_reading': endReading,
      'hours_used': executionHours, // Calculated hours
      'notes': notes,
      'logged_by': userId,
      'logged_at': DateTime.now().toIso8601String(),
    });

    // Update total hours via RPC; skip direct column updates to avoid schema-cache issues
    await _client.rpc(
      'increment_machinery_hours',
      params: {'p_machinery_id': machineryId, 'p_hours': executionHours},
    );
  }

  Stream<List<MachineryLog>> streamMachineryLogsByProject(String projectId) {
    return _client
        .from('machinery_logs')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .order('logged_at', ascending: false)
        .map((dataList) {
          // For each log, manually fetch the machinery details since stream doesn't support select joins
          return dataList.map((json) {
            // Note: Stream API doesn't support joins directly in the same way as select()
            // We need to either:
            // 1. Use the regular query with periodic refresh
            // 2. Manually fetch machinery details for each log
            // 3. Include machinery_id and fetch separately
            // For now, we'll rely on the regular query or need to refactor
            return MachineryLog.fromJson(json);
          }).toList();
        });
  }

  /// Delete a machinery log (soft by delete)
  Future<void> deleteMachineryLog({
    required String logId,
    required String projectId,
    String? note,
  }) async {
    await _client.from('machinery_logs').delete().eq('id', logId);
    await _client.rpc(
      'log_operation',
      params: {
        'p_operation_type': 'delete',
        'p_entity_type': 'machinery',
        'p_entity_id': logId,
        'p_title': '[DELETE] Machinery log',
        'p_description': note ?? '',
        'p_project_id': projectId,
      },
    );
  }
}
