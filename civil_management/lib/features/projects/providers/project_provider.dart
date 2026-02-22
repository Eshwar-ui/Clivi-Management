import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_client.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/project_model.dart';
import '../data/repositories/project_repository.dart';

// ============================================================
// REPOSITORY PROVIDER
// ============================================================

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository();
});

// ============================================================
// PROJECT LIST STATE
// ============================================================

class ProjectListState {
  final List<ProjectModel> projects;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String searchQuery;
  final ProjectStatus? statusFilter;
  final int currentPage;
  final bool hasMore;

  const ProjectListState({
    this.projects = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter,
    this.currentPage = 0,
    this.hasMore = true,
  });

  ProjectListState copyWith({
    List<ProjectModel>? projects,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? searchQuery,
    ProjectStatus? statusFilter,
    int? currentPage,
    bool? hasMore,
    bool clearError = false,
    bool clearStatusFilter = false,
  }) {
    return ProjectListState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ============================================================
// PROJECT LIST NOTIFIER
// ============================================================

class ProjectListNotifier extends StateNotifier<ProjectListState> {
  final ProjectRepository _repository;
  final Ref _ref;
  static const int _pageSize = 20;
  static const Duration _debounceDuration = Duration(milliseconds: 400);
  Timer? _debounceTimer;

  ProjectListNotifier(this._repository, this._ref)
    : super(const ProjectListState()) {
    loadProjects();
  }

  /// Check if user is admin (can see all projects)
  bool get _isAdmin {
    final role = _ref.read(userRoleProvider);
    return role == UserRole.admin || role == UserRole.superAdmin;
  }

  /// Get current user ID
  String? get _currentUserId => _ref.read(currentUserProvider)?.id;

  /// Load projects (initial load or refresh)
  Future<void> loadProjects() async {
    if (state.isLoading) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true, currentPage: 0);

      List<ProjectModel> projects;

      if (_isAdmin) {
        // Admins see all projects
        projects = await _repository.getProjects(
          search: state.searchQuery.isEmpty ? null : state.searchQuery,
          status: state.statusFilter,
          page: 0,
          pageSize: _pageSize,
        );
      } else {
        // Site managers see only assigned projects
        if (_currentUserId == null) {
          projects = [];
        } else {
          projects = await _repository.getAssignedProjects(_currentUserId!);
        }
      }

      state = state.copyWith(
        projects: projects,
        isLoading: false,
        hasMore: projects.length >= _pageSize,
      );
    } catch (e) {
      logger.e('Failed to load projects: $e');
      state = state.copyWith(
        isLoading: false,
        error: ExceptionHandler.getMessage(e),
      );
    }
  }

  /// Load more projects (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || !_isAdmin) return;

    try {
      state = state.copyWith(isLoadingMore: true);

      final nextPage = state.currentPage + 1;
      final newProjects = await _repository.getProjects(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        status: state.statusFilter,
        page: nextPage,
        pageSize: _pageSize,
      );

      state = state.copyWith(
        projects: [...state.projects, ...newProjects],
        isLoadingMore: false,
        currentPage: nextPage,
        hasMore: newProjects.length >= _pageSize,
      );
    } catch (e) {
      logger.e('Failed to load more projects: $e');
      state = state.copyWith(
        isLoadingMore: false,
        error: ExceptionHandler.getMessage(e),
      );
    }
  }

  /// Search projects with debouncing to prevent rapid API calls
  void search(String query) {
    _debounceTimer?.cancel();
    state = state.copyWith(searchQuery: query);

    _debounceTimer = Timer(_debounceDuration, () {
      loadProjects();
    });
  }

  /// Filter by status
  Future<void> filterByStatus(ProjectStatus? status) async {
    _debounceTimer?.cancel();
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    );
    await loadProjects();
  }

  /// Refresh projects
  Future<void> refresh() async {
    _debounceTimer?.cancel();
    await loadProjects();
  }

  /// Add project to list (after creation)
  void addProject(ProjectModel project) {
    state = state.copyWith(projects: [project, ...state.projects]);
  }

  /// Update project in list
  void updateProject(ProjectModel project) {
    final index = state.projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      final updatedList = [...state.projects];
      updatedList[index] = project;
      state = state.copyWith(projects: updatedList);
    }
  }

  /// Remove project from list
  void removeProject(String projectId) {
    state = state.copyWith(
      projects: state.projects.where((p) => p.id != projectId).toList(),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// ============================================================
// PROJECT DETAIL STATE
// ============================================================

class ProjectDetailState {
  final ProjectModel? project;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const ProjectDetailState({
    this.project,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  ProjectDetailState copyWith({
    ProjectModel? project,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return ProjectDetailState(
      project: project ?? this.project,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ============================================================
// PROJECT DETAIL NOTIFIER
// ============================================================

class ProjectDetailNotifier extends StateNotifier<ProjectDetailState> {
  final ProjectRepository _repository;
  final Ref _ref;
  final String projectId;

  ProjectDetailNotifier(this._repository, this._ref, this.projectId)
    : super(const ProjectDetailState()) {
    loadProject();
  }

  String? get _currentUserId => _ref.read(currentUserProvider)?.id;

  /// Load project details
  Future<void> loadProject() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final project = await _repository.getProjectById(projectId);

      state = state.copyWith(project: project, isLoading: false);
    } catch (e) {
      logger.e('Failed to load project: $e');
      state = state.copyWith(
        isLoading: false,
        error: ExceptionHandler.getMessage(e),
      );
    }
  }

  /// Update project
  Future<bool> updateProject(Map<String, dynamic> updates) async {
    try {
      state = state.copyWith(isSaving: true, clearError: true);

      final updated = await _repository.updateProject(projectId, updates);

      state = state.copyWith(project: updated, isSaving: false);

      // Update in list
      _ref.read(projectListProvider.notifier).updateProject(updated);

      return true;
    } catch (e) {
      logger.e('Failed to update project: $e');
      state = state.copyWith(
        isSaving: false,
        error: ExceptionHandler.getMessage(e),
      );
      return false;
    }
  }

  /// Delete project
  Future<bool> deleteProject() async {
    try {
      state = state.copyWith(isSaving: true, clearError: true);

      await _repository.deleteProject(projectId);

      // Remove from list
      _ref.read(projectListProvider.notifier).removeProject(projectId);

      return true;
    } catch (e) {
      logger.e('Failed to delete project: $e');
      state = state.copyWith(
        isSaving: false,
        error: ExceptionHandler.getMessage(e),
      );
      return false;
    }
  }

  /// Refresh project
  Future<void> refresh() async {
    await loadProject();
  }
}

// ============================================================
// SITE MANAGER SELECTION STATE
// ============================================================

class SiteManagerSelectionState {
  final List<SiteManagerModel> managers;
  final Set<String> selectedIds;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const SiteManagerSelectionState({
    this.managers = const [],
    this.selectedIds = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  SiteManagerSelectionState copyWith({
    List<SiteManagerModel>? managers,
    Set<String>? selectedIds,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return SiteManagerSelectionState(
      managers: managers ?? this.managers,
      selectedIds: selectedIds ?? this.selectedIds,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ============================================================
// SITE MANAGER SELECTION NOTIFIER
// ============================================================

class SiteManagerSelectionNotifier
    extends StateNotifier<SiteManagerSelectionState> {
  final ProjectRepository _repository;
  final Ref _ref;
  final String projectId;

  SiteManagerSelectionNotifier(this._repository, this._ref, this.projectId)
    : super(const SiteManagerSelectionState()) {
    loadManagers();
  }

  String? get _currentUserId => _ref.read(currentUserProvider)?.id;

  /// Load site managers with assignment status
  Future<void> loadManagers() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final managers = await _repository.getSiteManagersWithAssignmentStatus(
        projectId,
      );

      final selectedIds = managers
          .where((m) => m.isAssigned)
          .map((m) => m.id)
          .toSet();

      state = state.copyWith(
        managers: managers,
        selectedIds: selectedIds,
        isLoading: false,
      );
    } catch (e) {
      logger.e('Failed to load managers: $e');
      state = state.copyWith(
        isLoading: false,
        error: ExceptionHandler.getMessage(e),
      );
    }
  }

  /// Toggle manager selection
  void toggleManager(String managerId) {
    final newSelectedIds = Set<String>.from(state.selectedIds);
    if (newSelectedIds.contains(managerId)) {
      newSelectedIds.remove(managerId);
    } else {
      newSelectedIds.add(managerId);
    }
    state = state.copyWith(selectedIds: newSelectedIds);
  }

  /// Save assignments
  Future<bool> saveAssignments() async {
    if (_currentUserId == null) return false;

    try {
      state = state.copyWith(isSaving: true, clearError: true);

      await _repository.updateAssignments(
        projectId: projectId,
        assignedUserIds: state.selectedIds.toList(),
        assignedBy: _currentUserId!,
      );

      // Refresh project detail to get updated assignments
      _ref.read(projectDetailProvider(projectId).notifier).refresh();

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      logger.e('Failed to save assignments: $e');
      state = state.copyWith(
        isSaving: false,
        error: ExceptionHandler.getMessage(e),
      );
      return false;
    }
  }
}

// ============================================================
// CREATE PROJECT STATE
// ============================================================

class CreateProjectState {
  final bool isLoading;
  final String? error;
  final ProjectModel? createdProject;

  const CreateProjectState({
    this.isLoading = false,
    this.error,
    this.createdProject,
  });

  CreateProjectState copyWith({
    bool? isLoading,
    String? error,
    ProjectModel? createdProject,
    bool clearError = false,
  }) {
    return CreateProjectState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      createdProject: createdProject ?? this.createdProject,
    );
  }
}

// ============================================================
// CREATE PROJECT NOTIFIER
// ============================================================

class CreateProjectNotifier extends StateNotifier<CreateProjectState> {
  final ProjectRepository _repository;
  final Ref _ref;

  CreateProjectNotifier(this._repository, this._ref)
    : super(const CreateProjectState());

  String? get _currentUserId => _ref.read(currentUserProvider)?.id;

  /// Create new project
  Future<ProjectModel?> createProject(ProjectModel project) async {
    if (_currentUserId == null) {
      state = state.copyWith(error: 'User not authenticated');
      return null;
    }

    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final created = await _repository.createProject(project, _currentUserId!);

      // Add to list
      _ref.read(projectListProvider.notifier).addProject(created);

      state = state.copyWith(isLoading: false, createdProject: created);

      return created;
    } catch (e) {
      logger.e('Failed to create project: $e');
      state = state.copyWith(
        isLoading: false,
        error: ExceptionHandler.getMessage(e),
      );
      return null;
    }
  }

  /// Reset state
  void reset() {
    state = const CreateProjectState();
  }
}

// ============================================================
// PROVIDERS
// ============================================================

/// Project list provider
final projectListProvider =
    StateNotifierProvider<ProjectListNotifier, ProjectListState>((ref) {
      final repository = ref.watch(projectRepositoryProvider);
      return ProjectListNotifier(repository, ref);
    });

/// Project detail provider (family for different project IDs)
final projectDetailProvider =
    StateNotifierProvider.family<
      ProjectDetailNotifier,
      ProjectDetailState,
      String
    >((ref, projectId) {
      final repository = ref.watch(projectRepositoryProvider);
      return ProjectDetailNotifier(repository, ref, projectId);
    });

/// Site manager selection provider (family for different project IDs)
final siteManagerSelectionProvider =
    StateNotifierProvider.family<
      SiteManagerSelectionNotifier,
      SiteManagerSelectionState,
      String
    >((ref, projectId) {
      final repository = ref.watch(projectRepositoryProvider);
      return SiteManagerSelectionNotifier(repository, ref, projectId);
    });

/// Create project provider
final createProjectProvider =
    StateNotifierProvider<CreateProjectNotifier, CreateProjectState>((ref) {
      final repository = ref.watch(projectRepositoryProvider);
      return CreateProjectNotifier(repository, ref);
    });

/// Project stats provider
final projectStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getProjectStats();
});

/// Project material breakdown provider (family for different project IDs)
final projectMaterialBreakdownProvider =
    FutureProvider.family<List<MaterialBreakdown>, String>((
      ref,
      projectId,
    ) async {
      final repository = ref.watch(projectRepositoryProvider);
      return repository.getMaterialBreakdown(projectId);
    });
