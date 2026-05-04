import 'package:hive_flutter/hive_flutter.dart';
import '../../features/projects/data/models/project_model.dart';
import '../config/supabase_client.dart';

/// Local database service using Hive for offline persistence
/// Implements cache-first strategy for faster app startup
class LocalDatabaseService {
  static const String _projectsBoxName = 'projects';
  static const String _userProfileBoxName = 'user_profile';
  static const String _metadataBoxName = 'metadata';

  static LocalDatabaseService? _instance;
  static LocalDatabaseService get instance => _instance!;

  late Box<Map> _projectsBox;
  late Box<Map> _userProfileBox;
  late Box<dynamic> _metadataBox;

  LocalDatabaseService._();

  /// Initialize Hive and open boxes
  static Future<void> init() async {
    await Hive.initFlutter();

    _instance = LocalDatabaseService._();
    await _instance!._openBoxes();
  }

  Future<void> _openBoxes() async {
    _projectsBox = await Hive.openBox<Map>(_projectsBoxName);
    _userProfileBox = await Hive.openBox<Map>(_userProfileBoxName);
    _metadataBox = await Hive.openBox<dynamic>(_metadataBoxName);
  }

  // ============================================================
  // PROJECTS
  // ============================================================

  /// Get cached projects
  List<ProjectModel> getProjects() {
    try {
      final results = <ProjectModel>[];
      for (final entry in _projectsBox.values) {
        try {
          final json = _deepConvertMap(entry);
          // Skip entries that don't have required fields
          if (json['id'] == null || json['name'] == null) continue;
          results.add(ProjectModel.fromJson(json));
        } catch (e) {
          // Skip corrupted individual entries
          logger.w('Skipping corrupted cache entry: $e');
        }
      }
      return results;
    } catch (e) {
      logger.w('Failed to read projects from cache: $e');
      // Clear corrupted cache
      _projectsBox.clear();
      return [];
    }
  }

  /// Recursively convert Hive map types to standard Dart maps
  Map<String, dynamic> _deepConvertMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), _deepConvertMap(value));
        } else if (value is List) {
          return MapEntry(
            key.toString(),
            value.map((item) {
              if (item is Map) return _deepConvertMap(item);
              return item;
            }).toList(),
          );
        }
        return MapEntry(key.toString(), value);
      });
    }
    return {};
  }

  /// Save projects to cache
  Future<void> saveProjects(List<ProjectModel> projects) async {
    try {
      await _projectsBox.clear();
      for (final project in projects) {
        await _projectsBox.put(project.id, project.toJson());
      }
      await _setLastSync(_projectsBoxName);
    } catch (e) {
      logger.w('Failed to save projects to cache: $e');
    }
  }

  /// Get a single project by ID
  ProjectModel? getProject(String id) {
    try {
      final json = _projectsBox.get(id);
      if (json == null) return null;
      return ProjectModel.fromJson(Map<String, dynamic>.from(json));
    } catch (e) {
      logger.w('Failed to read project from cache: $e');
      return null;
    }
  }

  /// Save a single project
  Future<void> saveProject(ProjectModel project) async {
    try {
      await _projectsBox.put(project.id, project.toJson());
    } catch (e) {
      logger.w('Failed to save project to cache: $e');
    }
  }

  /// Remove a project from cache
  Future<void> removeProject(String id) async {
    try {
      await _projectsBox.delete(id);
    } catch (e) {
      logger.w('Failed to remove project from cache: $e');
    }
  }

  /// Clear all projects from cache
  Future<void> clearProjectsCache() async {
    try {
      await _projectsBox.clear();
    } catch (e) {
      logger.w('Failed to clear projects cache: $e');
    }
  }

  // ============================================================
  // USER PROFILE
  // ============================================================

  /// Get cached user profile
  Map<String, dynamic>? getUserProfile() {
    try {
      final json = _userProfileBox.get('current');
      if (json == null) return null;
      return Map<String, dynamic>.from(json);
    } catch (e) {
      logger.w('Failed to read user profile from cache: $e');
      return null;
    }
  }

  /// Save user profile to cache
  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    try {
      await _userProfileBox.put('current', profile);
    } catch (e) {
      logger.w('Failed to save user profile to cache: $e');
    }
  }

  // ============================================================
  // DASHBOARD STATS
  // ============================================================

  /// Get cached dashboard stats
  Map<String, dynamic>? getDashboardStats() {
    try {
      final json = _metadataBox.get('dashboard_stats');
      if (json == null) return null;
      return Map<String, dynamic>.from(json as Map);
    } catch (e) {
      logger.w('Failed to read dashboard stats from cache: $e');
      return null;
    }
  }

  /// Save dashboard stats to cache
  Future<void> saveDashboardStats(Map<String, dynamic> stats) async {
    try {
      await _metadataBox.put('dashboard_stats', stats);
      await _setLastSync('dashboard');
    } catch (e) {
      logger.w('Failed to save dashboard stats to cache: $e');
    }
  }

  /// Check if dashboard cache is stale
  bool isDashboardStale({Duration maxAge = const Duration(minutes: 5)}) {
    return isCacheStale('dashboard', maxAge: maxAge);
  }

  // ============================================================
  // METADATA & UTILITIES
  // ============================================================

  /// Set last sync time for a box
  Future<void> _setLastSync(String boxName) async {
    await _metadataBox.put(
      '${boxName}_last_sync',
      DateTime.now().toIso8601String(),
    );
  }

  /// Get last sync time for a box
  DateTime? getLastSync(String boxName) {
    final timestamp = _metadataBox.get('${boxName}_last_sync') as String?;
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  /// Check if cache is stale (older than duration)
  bool isCacheStale(
    String boxName, {
    Duration maxAge = const Duration(minutes: 5),
  }) {
    final lastSync = getLastSync(boxName);
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > maxAge;
  }

  // ============================================================
  // RECENT ACTIVITY
  // ============================================================

  /// Get cached recent activity
  List<Map<String, dynamic>>? getRecentActivity() {
    try {
      final json = _metadataBox.get('recent_activity');
      if (json == null) return null;

      if (json is List) {
        return json.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return null;
    } catch (e) {
      logger.w('Failed to read recent activity from cache: $e');
      return null;
    }
  }

  /// Save recent activity to cache
  Future<void> saveRecentActivity(List<Map<String, dynamic>> activities) async {
    try {
      await _metadataBox.put('recent_activity', activities);
    } catch (e) {
      logger.w('Failed to save recent activity to cache: $e');
    }
  }

  // ============================================================
  // APP STATE PERSISTENCE (Process Death Recovery)
  // ============================================================

  static const int _cacheVersion = 1;

  /// Get cached app state (survives process death)
  Map<String, dynamic>? getAppState() {
    try {
      // Check cache version
      final version = _metadataBox.get('cache_version') as int?;
      if (version != _cacheVersion) {
        logger.w('Cache version mismatch, clearing stale data');
        clearAll();
        return null;
      }

      final state = _metadataBox.get('app_state');
      if (state == null) return null;
      return Map<String, dynamic>.from(state as Map);
    } catch (e) {
      logger.w('Failed to read app state: $e');
      return null;
    }
  }

  /// Save app state for process death recovery
  Future<void> saveAppState(Map<String, dynamic> state) async {
    try {
      await _metadataBox.put('app_state', state);
      await _metadataBox.put('cache_version', _cacheVersion);
    } catch (e) {
      logger.w('Failed to save app state: $e');
    }
  }

  /// Get selected project ID (for quick restore)
  String? getSelectedProjectId() {
    return _metadataBox.get('selected_project_id') as String?;
  }

  /// Save selected project ID
  Future<void> saveSelectedProjectId(String? projectId) async {
    if (projectId == null) {
      await _metadataBox.delete('selected_project_id');
    } else {
      await _metadataBox.put('selected_project_id', projectId);
    }
  }

  /// Get active filters
  Map<String, dynamic>? getActiveFilters() {
    try {
      final filters = _metadataBox.get('active_filters');
      if (filters == null) return null;
      return Map<String, dynamic>.from(filters as Map);
    } catch (e) {
      return null;
    }
  }

  /// Save active filters
  Future<void> saveActiveFilters(Map<String, dynamic>? filters) async {
    if (filters == null) {
      await _metadataBox.delete('active_filters');
    } else {
      await _metadataBox.put('active_filters', filters);
    }
  }

  /// Clear all cached data (call on logout)
  Future<void> clearAll() async {
    await _projectsBox.clear();
    await _userProfileBox.clear();
    await _metadataBox.clear();
    logger.i('Local database cleared');
  }

  /// Close all boxes
  Future<void> close() async {
    await Hive.close();
  }
}
