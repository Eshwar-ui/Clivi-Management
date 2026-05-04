import 'package:civil_management/core/utils/cached_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/services/local_database_service.dart';
import '../models/project_model.dart';

/// Repository for project-related Supabase operations
/// Implements cache-first strategy for offline support
class ProjectRepository {
  final SupabaseClient _client;
  final CachedRepository<List<ProjectModel>> _memoryCache = CachedRepository();
  final LocalDatabaseService _localDb = LocalDatabaseService.instance;

  ProjectRepository({SupabaseClient? client}) : _client = client ?? supabase;

  // ============================================================
  // PROJECT CRUD OPERATIONS
  // ============================================================

  /// Get all projects with cache-first strategy
  /// Returns cached data immediately, refreshes from API in background
  Future<List<ProjectModel>> getProjects({
    String? search,
    ProjectStatus? status,
    int page = 0,
    int pageSize = 20,
    bool forceRefresh = false,
  }) async {
    // For filtered/searched queries, skip disk cache (use memory cache only)
    if (search != null || status != null || page > 0) {
      return _fetchFromApi(
        search: search,
        status: status,
        page: page,
        pageSize: pageSize,
      );
    }

    // CACHE-FIRST: Return cached data immediately for main list
    if (!forceRefresh) {
      final cached = _localDb.getProjects();
      if (cached.isNotEmpty) {
        logger.i('Returning ${cached.length} cached projects');
        // Refresh in background (don't await)
        _refreshProjectsInBackground();
        return cached;
      }
    }

    // No cache, fetch from API
    final projects = await _fetchFromApi(
      search: search,
      status: status,
      page: page,
      pageSize: pageSize,
    );

    // Save to local cache
    await _localDb.saveProjects(projects);

    return projects;
  }

  /// Refresh projects from API in background
  Future<void> _refreshProjectsInBackground() async {
    try {
      final freshProjects = await _fetchFromApi();
      await _localDb.saveProjects(freshProjects);
      logger.i(
        'Background refresh: saved ${freshProjects.length} projects to cache',
      );
    } catch (e) {
      logger.w('Background refresh failed: $e');
    }
  }

  /// Get projects using cursor-based pagination (infinite scroll)
  /// More efficient than offset pagination, prevents duplicates on insert
  Future<List<ProjectModel>> getProjectsCursor({
    String? cursorCreatedAt,
    String? cursorId,
    int limit = 20,
    ProjectStatus? status,
  }) async {
    try {
      var query = _client.from('projects').select('''
        *,
        project_assignments(
          id,
          project_id,
          user_id,
          assigned_role,
          assigned_at,
          user_profiles!user_id(id, full_name, phone)
        )
      ''');

      // Apply status filter
      if (status != null) {
        query = query.eq('status', status.value);
      }

      // Apply cursor filter for pagination
      if (cursorCreatedAt != null && cursorId != null) {
        // Cursor: get items older than current cursor
        query = query.or(
          'created_at.lt.$cursorCreatedAt,'
          'and(created_at.eq.$cursorCreatedAt,id.lt.$cursorId)',
        );
      }
      final response = await query
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ProjectModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch projects with cursor: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Fetch projects from Supabase API
  Future<List<ProjectModel>> _fetchFromApi({
    String? search,
    ProjectStatus? status,
    int page = 0,
    int pageSize = 20,
  }) async {
    final cacheKey = 'projects_${search}_${status}_${page}_$pageSize';
    return _memoryCache.getOrFetch(cacheKey, () async {
      try {
        var query = _client.from('projects').select('''
            *,
            project_assignments(
              id,
              project_id,
              user_id,
              assigned_role,
              assigned_at,
              user_profiles!user_id(id, full_name, phone)
            )
          ''');

        // Apply search filter
        if (search != null && search.isNotEmpty) {
          query = query.or('name.ilike.%$search%,location.ilike.%$search%');
        }

        // Apply status filter
        if (status != null) {
          query = query.eq('status', status.value);
        }

        // Apply pagination and ordering
        final response = await query
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false)
            .range(page * pageSize, (page + 1) * pageSize - 1);

        return (response as List)
            .map((json) => ProjectModel.fromJson(json))
            .toList();
      } on PostgrestException catch (e) {
        logger.e('Failed to fetch projects: ${e.message}');
        throw DatabaseException.fromPostgrest(e);
      }
    });
  }

  /// Get projects assigned to a specific site manager
  /// Uses a single JOIN query instead of N+1 pattern for better performance
  Future<List<ProjectModel>> getAssignedProjects(String userId) async {
    try {
      // Single JOIN query - uses !inner to filter projects with matching assignments
      final response = await _client
          .from('projects')
          .select('''
            *,
            project_assignments!inner(
              id,
              project_id,
              user_id,
              assigned_role,
              assigned_at,
              user_profiles!user_id(id, full_name, phone)
            )
          ''')
          .eq('project_assignments.user_id', userId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProjectModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch assigned projects: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Get single project by ID
  Future<ProjectModel> getProjectById(String projectId) async {
    try {
      final response = await _client
          .from('projects')
          .select('''
            *,
            project_assignments(
              id,
              project_id,
              user_id,
              assigned_role,
              assigned_at,
              user_profiles!user_id(id, full_name, phone)
            )
          ''')
          .eq('id', projectId)
          .single();

      return ProjectModel.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch project: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Create new project
  Future<ProjectModel> createProject(
    ProjectModel project,
    String userId,
  ) async {
    try {
      final response = await _client
          .from('projects')
          .insert(project.toInsertJson(userId))
          .select()
          .single();

      logger.i('Project created: ${response['name']}');
      _memoryCache.invalidateAll();
      return ProjectModel.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('Failed to create project: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Update existing project
  Future<ProjectModel> updateProject(
    String projectId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('projects')
          .update(updates)
          .eq('id', projectId)
          .select()
          .single();

      logger.i('Project updated: ${response['name']}');
      _memoryCache.invalidateAll();
      return ProjectModel.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('Failed to update project: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Soft delete project (sets deleted_at timestamp)
  Future<void> deleteProject(String projectId) async {
    try {
      // Use RPC for soft delete with proper logging
      final result = await _client.rpc(
        'soft_delete_project',
        params: {'p_project_id': projectId},
      );

      if (result == true) {
        logger.i('Project soft deleted: $projectId');
        _memoryCache.invalidateAll();
        // Clear from local cache too
        await _localDb.clearProjectsCache();
      } else {
        throw DatabaseException('Failed to delete project');
      }
    } on PostgrestException catch (e) {
      logger.e('Failed to delete project: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Get project statistics (material, labor, machinery counts)
  Future<ProjectStats> getProjectStatsById(String projectId) async {
    try {
      final response = await _client.rpc(
        'get_project_stats',
        params: {'p_project_id': projectId},
      );

      if (response == null) {
        return ProjectStats.empty;
      }

      return ProjectStats.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch project stats: ${e.message}');
      return ProjectStats.empty;
    }
  }

  /// Get material breakdown for a project
  Future<List<MaterialBreakdown>> getMaterialBreakdown(String projectId) async {
    try {
      final response = await _client.rpc(
        'get_project_material_breakdown',
        params: {'p_project_id': projectId},
      );

      if (response == null || response is! List) {
        return [];
      }

      return response
          .map(
            (json) => MaterialBreakdown.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch material breakdown: ${e.message}');
      return [];
    }
  }

  // ============================================================
  // PROJECT ASSIGNMENTS
  // ============================================================

  /// Get all site managers (for assignment dropdown)
  Future<List<SiteManagerModel>> getSiteManagers() async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('role', 'site_manager')
          .order('full_name');

      return (response as List)
          .map((json) => SiteManagerModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch site managers: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Get site managers with assignment status for a project
  Future<List<SiteManagerModel>> getSiteManagersWithAssignmentStatus(
    String projectId,
  ) async {
    try {
      // Get all site managers
      final managersResponse = await _client
          .from('user_profiles')
          .select()
          .eq('role', 'site_manager')
          .order('full_name');

      // Get current assignments for this project
      final assignmentsResponse = await _client
          .from('project_assignments')
          .select('user_id')
          .eq('project_id', projectId);

      final assignedUserIds = (assignmentsResponse as List)
          .map((a) => a['user_id'] as String)
          .toSet();

      return (managersResponse as List)
          .map(
            (json) => SiteManagerModel.fromJson(
              json,
              isAssigned: assignedUserIds.contains(json['id']),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch site managers: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Assign site manager to project
  Future<void> assignManager({
    required String projectId,
    required String userId,
    required String assignedBy,
    String assignedRole = 'manager',
  }) async {
    try {
      await _client.from('project_assignments').insert({
        'project_id': projectId,
        'user_id': userId,
        'assigned_role': assignedRole,
        'assigned_by': assignedBy,
      });

      logger.i('Manager assigned to project: $userId -> $projectId');
    } on PostgrestException catch (e) {
      logger.e('Failed to assign manager: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Remove site manager from project
  Future<void> removeAssignment({
    required String projectId,
    required String userId,
  }) async {
    try {
      await _client
          .from('project_assignments')
          .delete()
          .eq('project_id', projectId)
          .eq('user_id', userId);

      logger.i('Manager removed from project: $userId <- $projectId');
    } on PostgrestException catch (e) {
      logger.e('Failed to remove assignment: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Update multiple assignments (bulk assign/unassign)
  Future<void> updateAssignments({
    required String projectId,
    required List<String> assignedUserIds,
    required String assignedBy,
  }) async {
    try {
      // Get current assignments
      final currentResponse = await _client
          .from('project_assignments')
          .select('user_id')
          .eq('project_id', projectId);

      final currentUserIds = (currentResponse as List)
          .map((a) => a['user_id'] as String)
          .toSet();

      final newUserIds = assignedUserIds.toSet();

      // Users to add
      final toAdd = newUserIds.difference(currentUserIds);
      // Users to remove
      final toRemove = currentUserIds.difference(newUserIds);

      // Remove unassigned users
      if (toRemove.isNotEmpty) {
        await _client
            .from('project_assignments')
            .delete()
            .eq('project_id', projectId)
            .inFilter('user_id', toRemove.toList());
      }

      // Add newly assigned users
      if (toAdd.isNotEmpty) {
        final insertData = toAdd
            .map(
              (userId) => {
                'project_id': projectId,
                'user_id': userId,
                'assigned_role': 'manager',
                'assigned_by': assignedBy,
              },
            )
            .toList();

        await _client.from('project_assignments').insert(insertData);
      }

      logger.i('Assignments updated for project: $projectId');
    } on PostgrestException catch (e) {
      logger.e('Failed to update assignments: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }

  /// Get project statistics (for dashboard)
  /// Optimized to minimize data transfer - only fetches status field
  Future<Map<String, int>> getProjectStats() async {
    try {
      // Fetch only the status column for efficiency
      final response = await _client
          .from('projects')
          .select('status')
          .isFilter('deleted_at', null)
          .limit(10000); // Safety limit to prevent unbounded queries

      final stats = <String, int>{
        'total': 0,
        'planning': 0,
        'in_progress': 0,
        'on_hold': 0,
        'completed': 0,
        'cancelled': 0,
      };

      final dataList = response as List;
      stats['total'] = dataList.length;

      for (final row in dataList) {
        final status = row['status'] as String?;
        if (status != null && stats.containsKey(status)) {
          stats[status] = (stats[status] ?? 0) + 1;
        }
      }

      return stats;
    } on PostgrestException catch (e) {
      logger.e('Failed to fetch project stats: ${e.message}');
      throw DatabaseException.fromPostgrest(e);
    }
  }
}
