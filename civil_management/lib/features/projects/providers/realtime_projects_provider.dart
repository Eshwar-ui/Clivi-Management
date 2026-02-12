import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../data/models/project_model.dart';
import 'project_provider.dart';

/// Realtime event types
enum RealtimeEventType { insert, update, delete }

/// Represents a realtime event for a project
class RealtimeProjectEvent {
  final RealtimeEventType type;
  final String? projectId;
  final Map<String, dynamic>? newRecord;
  final Map<String, dynamic>? oldRecord;

  RealtimeProjectEvent({
    required this.type,
    this.projectId,
    this.newRecord,
    this.oldRecord,
  });

  factory RealtimeProjectEvent.fromPayload(PostgresChangePayload payload) {
    RealtimeEventType type;
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        type = RealtimeEventType.insert;
        break;
      case PostgresChangeEvent.update:
        type = RealtimeEventType.update;
        break;
      case PostgresChangeEvent.delete:
        type = RealtimeEventType.delete;
        break;
      default:
        type = RealtimeEventType.update;
    }

    return RealtimeProjectEvent(
      type: type,
      projectId: (payload.newRecord['id'] ?? payload.oldRecord['id'])
          ?.toString(),
      newRecord: payload.newRecord,
      oldRecord: payload.oldRecord,
    );
  }
}

/// Provider for realtime project updates
/// Listens to INSERT, UPDATE, DELETE events on projects table
final realtimeProjectsProvider = StreamProvider<RealtimeProjectEvent>((ref) {
  final controller = StreamController<RealtimeProjectEvent>();

  // Subscribe to realtime changes
  final channel = supabase
      .channel(
        'projects_realtime',
        opts: const RealtimeChannelConfig(ack: true),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'projects',
        callback: (payload) {
          final event = RealtimeProjectEvent.fromPayload(payload);
          controller.add(event);
          logger.i(
            'Realtime: ${event.type.name} on project ${event.projectId}',
          );
        },
      );

  channel.subscribe((status, error) {
    if (status == RealtimeSubscribeStatus.subscribed) {
      logger.i('Realtime: projects channel subscribed');
    } else if (status == RealtimeSubscribeStatus.channelError ||
        status == RealtimeSubscribeStatus.timedOut ||
        status == RealtimeSubscribeStatus.closed) {
      logger.w(
        'Realtime channel issue ($status): ${error?.toString() ?? 'no details'}',
      );
    }
  });

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// Notifier that handles realtime project updates
class RealtimeProjectsNotifier
    extends StateNotifier<AsyncValue<List<ProjectModel>>> {
  final Ref _ref;
  StreamSubscription? _subscription;

  RealtimeProjectsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    // Load initial data
    try {
      final repository = _ref.read(projectRepositoryProvider);
      final projects = await repository.getProjects();
      state = AsyncValue.data(projects);

      // Start listening to realtime events
      _listenToRealtimeEvents();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _listenToRealtimeEvents() {
    // Watch realtime provider for changes
    _ref.listen(realtimeProjectsProvider, (previous, next) {
      next.whenData((event) => _handleEvent(event));
    });
  }

  Future<void> _handleEvent(RealtimeProjectEvent event) async {
    final repository = _ref.read(projectRepositoryProvider);

    switch (event.type) {
      case RealtimeEventType.insert:
      case RealtimeEventType.update:
        // Refresh the full list to get updated data
        try {
          final refreshed = await repository.getProjects(forceRefresh: true);
          state = AsyncValue.data(refreshed);
        } catch (e, st) {
          logger.e('Failed to refresh after realtime event: $e');
          state = AsyncValue.error(e, st);
        }
        break;
      case RealtimeEventType.delete:
        // Remove the deleted project from current list
        final current = state.valueOrNull ?? [];
        state = AsyncValue.data(
          current.where((p) => p.id != event.projectId).toList(),
        );
        break;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider for live projects with realtime updates
final liveProjectsNotifierProvider =
    StateNotifierProvider<
      RealtimeProjectsNotifier,
      AsyncValue<List<ProjectModel>>
    >((ref) {
      return RealtimeProjectsNotifier(ref);
    });
