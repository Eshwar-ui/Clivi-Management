import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../models/dashboard_models.dart';

/// Repository for dashboard data operations
/// Uses RPC functions for efficient data fetching
class DashboardRepository {
  final SupabaseClient _client;

  DashboardRepository(this._client);

  /// Fetch dashboard statistics
  /// Calls the get_dashboard_stats RPC function
  Future<DashboardStats> getStats() async {
    try {
      final response = await _client.rpc('get_dashboard_stats');

      if (response == null) {
        return DashboardStats.empty;
      }

      return DashboardStats.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      logger.e('Failed to fetch dashboard stats: $e');
      throw DatabaseException('Failed to load dashboard statistics');
    }
  }

  /// Fetch recent activity for the activity feed
  /// [limit] - Number of items to fetch (default: 10)
  /// [offset] - Pagination offset (default: 0)
  /// [projectId] - Filter by specific project (optional)
  Future<List<OperationLog>> getRecentActivity({
    int limit = 10,
    int offset = 0,
    String? projectId,
  }) async {
    try {
      final response = await _client.rpc(
        'get_recent_activity',
        params: {
          'p_limit': limit,
          'p_offset': offset,
          if (projectId != null) 'p_project_id': projectId,
        },
      );

      final list = response as List<dynamic>? ?? [];
      if (list.isEmpty) {
        return [];
      }

      return list
          .map<OperationLog>((json) => OperationLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.e('Failed to fetch recent activity: $e');
      throw DatabaseException('Failed to load activity feed');
    }
  }

  /// Fetch active projects summary for dashboard cards
  /// [limit] - Number of projects to fetch (default: 10)
  Future<List<ProjectSummary>> getActiveProjectsSummary({int limit = 10}) async {
    try {
      final response = await _client.rpc(
        'get_active_projects_summary',
        params: {'p_limit': limit},
      );

      final list = response as List<dynamic>? ?? [];
      if (list.isEmpty) {
        return [];
      }

      return list
          .map<ProjectSummary>((json) => ProjectSummary.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.e('Failed to fetch active projects: $e');
      throw DatabaseException('Failed to load projects');
    }
  }

  /// Fetch active assigned projects summary for a specific user
  Future<List<ProjectSummary>> getActiveAssignedProjectsSummary(String userId, {int limit = 3}) async {
    try {
      final response = await _client
          .from('projects')
          .select('''
            id,
            name,
            project_type,
            status,
            progress,
            start_date,
            end_date,
            location,
            project_assignments!inner(
              user_id
            )
          ''')
          .eq('project_assignments.user_id', userId)
          .neq('status', 'completed')
          .neq('status', 'cancelled')
          .order('created_at', ascending: false)
          .limit(limit);

      final list = response as List<dynamic>? ?? [];
      if (list.isEmpty) {
        return [];
      }

      return list
          .map<ProjectSummary>((json) => ProjectSummary.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.e('Failed to fetch assigned projects summary: $e');
      throw DatabaseException('Failed to load projects');
    }
  }

  /// Log a custom operation to the activity feed
  Future<void> logOperation({
    required String operationType,
    required String entityType,
    required String entityId,
    required String title,
    String? description,
    String? projectId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.rpc(
        'log_operation',
        params: {
          'p_operation_type': operationType,
          'p_entity_type': entityType,
          'p_entity_id': entityId,
          'p_title': title,
          if (description != null) 'p_description': description,
          if (projectId != null) 'p_project_id': projectId,
          if (metadata != null) 'p_metadata': metadata,
        },
      );
    } catch (e) {
      logger.w('Failed to log operation: $e');
      // Don't throw - logging failures shouldn't break the app
    }
  }

  /// Subscribe to realtime operation log changes
  /// Returns a stream of new operation logs
  Stream<OperationLog> subscribeToActivity() {
    return _client
        .from('operation_logs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(1)
        .map((data) {
          if (data.isEmpty) return null;
          return OperationLog.fromJson(data.first);
        })
        .where((log) => log != null)
        .cast<OperationLog>();
  }
}
