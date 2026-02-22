import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_client.dart';
import '../../../core/services/local_database_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/dashboard_models.dart';
import '../data/repositories/dashboard_repository.dart';

class OperationsLiveCounts {
  final int vendors;
  final int machinery;
  final int siteManagers;
  final int workers;

  const OperationsLiveCounts({
    this.vendors = 0,
    this.machinery = 0,
    this.siteManagers = 0,
    this.workers = 0,
  });

  OperationsLiveCounts copyWith({
    int? vendors,
    int? machinery,
    int? siteManagers,
    int? workers,
  }) {
    return OperationsLiveCounts(
      vendors: vendors ?? this.vendors,
      machinery: machinery ?? this.machinery,
      siteManagers: siteManagers ?? this.siteManagers,
      workers: workers ?? this.workers,
    );
  }
}

/// Dashboard repository provider
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(supabase);
});

/// Dashboard stats state
class DashboardStatsState {
  final DashboardStats stats;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DateTime? lastFetched;

  const DashboardStatsState({
    this.stats = DashboardStats.empty,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.lastFetched,
  });

  DashboardStatsState copyWith({
    DashboardStats? stats,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
    DateTime? lastFetched,
  }) {
    return DashboardStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }
}

/// Dashboard stats notifier
class DashboardStatsNotifier extends StateNotifier<DashboardStatsState> {
  final DashboardRepository _repository;

  DashboardStatsNotifier(this._repository)
    : super(const DashboardStatsState()) {
    _loadCachedStats();
    fetchStats();
  }

  /// Load cached stats from local storage
  void _loadCachedStats() {
    try {
      final cached = LocalDatabaseService.instance.getDashboardStats();
      if (cached != null) {
        state = state.copyWith(
          stats: DashboardStats.fromJson(cached),
          lastFetched: LocalDatabaseService.instance.getLastSync('dashboard'),
        );
        logger.d('Loaded cached dashboard stats');
      }
    } catch (e) {
      logger.w('Failed to load cached stats: $e');
    }
  }

  /// Fetch fresh stats from server
  Future<void> fetchStats() async {
    // Show loading only if no cached data
    if (state.stats == DashboardStats.empty) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isRefreshing: true, clearError: true);
    }

    try {
      final stats = await _repository.getStats();
      state = state.copyWith(
        stats: stats,
        isLoading: false,
        isRefreshing: false,
        lastFetched: DateTime.now(),
      );

      // Cache the stats
      await LocalDatabaseService.instance.saveDashboardStats(stats.toJson());
    } catch (e) {
      logger.e('Failed to fetch dashboard stats: $e');
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh stats (for pull-to-refresh)
  Future<void> refresh() => fetchStats();
}

/// Dashboard stats provider
final dashboardStatsProvider =
    StateNotifierProvider<DashboardStatsNotifier, DashboardStatsState>((ref) {
      final repository = ref.watch(dashboardRepositoryProvider);
      return DashboardStatsNotifier(repository);
    });

/// Recent activity state
class RecentActivityState {
  final List<OperationLog> activities;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const RecentActivityState({
    this.activities = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  RecentActivityState copyWith({
    List<OperationLog>? activities,
    bool? isLoading,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return RecentActivityState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Recent activity notifier with pagination
class RecentActivityNotifier extends StateNotifier<RecentActivityState> {
  final DashboardRepository _repository;
  static const int _pageSize = 10;
  // ignore: unused_field
  StreamSubscription<OperationLog>? _subscription;

  RecentActivityNotifier(this._repository)
    : super(const RecentActivityState()) {
    _loadCachedActivity();
    fetchActivity();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Load cached activity from local storage
  void _loadCachedActivity() {
    try {
      final cached = LocalDatabaseService.instance.getRecentActivity();
      if (cached != null && cached.isNotEmpty) {
        final activities = cached
            .map((json) => OperationLog.fromJson(json))
            .toList();
        state = state.copyWith(activities: activities, isLoading: false);
      }
    } catch (e) {
      logger.w('Failed to load cached activity: $e');
    }
  }

  /// Subscribe to real-time updates
  void _subscribeToRealtime() {
    _subscription = _repository.subscribeToActivity().listen(
      (log) {
        // Prepend new log to the list
        state = state.copyWith(activities: [log, ...state.activities]);

        // Update cache
        if (state.activities.isNotEmpty) {
          LocalDatabaseService.instance.saveRecentActivity(
            state.activities.take(20).map((e) => e.toJson()).toList(),
          );
        }
      },
      onError: (e) {
        logger.w('Realtime subscription error: $e');
      },
    );
  }

  /// Fetch initial activity
  Future<void> fetchActivity() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final activities = await _repository.getRecentActivity(limit: _pageSize);
      state = state.copyWith(
        activities: activities,
        isLoading: false,
        hasMore: activities.length >= _pageSize,
      );

      // Cache the activities
      await LocalDatabaseService.instance.saveRecentActivity(
        activities.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      logger.e('Failed to fetch activity: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more activities
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final activities = await _repository.getRecentActivity(
        limit: _pageSize,
        offset: state.activities.length,
      );

      state = state.copyWith(
        activities: [...state.activities, ...activities],
        isLoading: false,
        hasMore: activities.length >= _pageSize,
      );
    } catch (e) {
      logger.e('Failed to load more activity: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Refresh activity list
  Future<void> refresh() => fetchActivity();
}

/// Recent activity provider
final recentActivityProvider =
    StateNotifierProvider<RecentActivityNotifier, RecentActivityState>((ref) {
      final repository = ref.watch(dashboardRepositoryProvider);
      return RecentActivityNotifier(repository);
    });


/// Active projects state
class ActiveProjectsState {
  final List<ProjectSummary> projects;
  final bool isLoading;
  final String? error;

  const ActiveProjectsState({
    this.projects = const [],
    this.isLoading = false,
    this.error,
  });

  ActiveProjectsState copyWith({
    List<ProjectSummary>? projects,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ActiveProjectsState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Active projects notifier
class ActiveProjectsNotifier extends StateNotifier<ActiveProjectsState> {
  final DashboardRepository _repository;
  final Ref _ref;

  ActiveProjectsNotifier(this._repository, this._ref)
    : super(const ActiveProjectsState()) {
    fetchProjects();
  }

  bool get _isAdmin {
    final role = _ref.read(userRoleProvider);
    return role == UserRole.admin || role == UserRole.superAdmin;
  }

  String? get _currentUserId => _ref.read(currentUserProvider)?.id;

  /// Fetch active projects
  Future<void> fetchProjects() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      List<ProjectSummary> projects;

      if (_isAdmin) {
        projects = await _repository.getActiveProjectsSummary();
      } else {
        if (_currentUserId == null) {
          projects = [];
        } else {
          projects = await _repository.getActiveAssignedProjectsSummary(_currentUserId!);
        }
      }

      state = state.copyWith(projects: projects, isLoading: false);
    } catch (e) {
      logger.e('Failed to fetch active projects: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh projects
  Future<void> refresh() => fetchProjects();
}

/// Active projects provider
final activeProjectsProvider =
    StateNotifierProvider<ActiveProjectsNotifier, ActiveProjectsState>((ref) {
      final repository = ref.watch(dashboardRepositoryProvider);
      return ActiveProjectsNotifier(repository, ref);
    });

/// Convenience providers
final dashboardStatsValueProvider = Provider<DashboardStats>((ref) {
  return ref.watch(dashboardStatsProvider).stats;
});

final isDashboardLoadingProvider = Provider<bool>((ref) {
  return ref.watch(dashboardStatsProvider).isLoading;
});

final recentActivitiesProvider = Provider<List<OperationLog>>((ref) {
  return ref.watch(recentActivityProvider).activities;
});

final activeProjectsListProvider = Provider<List<ProjectSummary>>((ref) {
  return ref.watch(activeProjectsProvider).projects;
});

/// Realtime counts for admin operations cards.
/// Keeps vendors, machinery, site managers and workers in sync with backend.
final operationsLiveCountsProvider = StreamProvider<OperationsLiveCounts>((
  ref,
) {
  final controller = StreamController<OperationsLiveCounts>();

  var counts = const OperationsLiveCounts();
  var hasVendors = false;
  var hasMachinery = false;
  var hasManagers = false;
  var hasWorkers = false;

  void emitIfReady() {
    if (hasVendors && hasMachinery && hasManagers && hasWorkers) {
      controller.add(counts);
    }
  }

  final subscriptions = <StreamSubscription<dynamic>>[
    supabase
        .from('suppliers')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .listen((rows) {
          counts = counts.copyWith(vendors: rows.length);
          hasVendors = true;
          emitIfReady();
        }),
    supabase.from('machinery').stream(primaryKey: ['id']).listen((rows) {
      counts = counts.copyWith(machinery: rows.length);
      hasMachinery = true;
      emitIfReady();
    }),
    supabase
        .from('user_profiles')
        .stream(primaryKey: ['id'])
        .eq('role', 'site_manager')
        .listen((rows) {
          counts = counts.copyWith(siteManagers: rows.length);
          hasManagers = true;
          emitIfReady();
        }),
    supabase
        .from('labour')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .listen((rows) {
          counts = counts.copyWith(workers: rows.length);
          hasWorkers = true;
          emitIfReady();
        }),
  ];

  ref.onDispose(() async {
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    await controller.close();
  });

  return controller.stream;
});
