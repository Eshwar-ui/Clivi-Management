import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/machinery_model.dart';
import '../data/models/machinery_log_model.dart';
import '../data/repositories/machinery_repository.dart';
import '../../../../core/config/supabase_client.dart';

final machineryRepositoryProvider = Provider<MachineryRepository>((ref) {
  return MachineryRepository(supabase);
});

// Logs Future Provider (Stream doesn't support joins properly)
final machineryLogsProvider = FutureProvider.family
    .autoDispose<List<MachineryLog>, String>((ref, projectId) async {
      final repo = ref.watch(machineryRepositoryProvider);
      return repo.getMachineryLogsByProject(projectId);
    });

// Machinery List (for dropdown)
final machineryListProvider = FutureProvider<List<MachineryModel>>((ref) async {
  final repo = ref.watch(machineryRepositoryProvider);
  return repo.getAllMachinery();
});

// Controller
class MachineryController extends StateNotifier<AsyncValue<void>> {
  final MachineryRepository _repository;

  MachineryController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> createMachinery({
    required String name,
    required String type,
    String? registrationNo,
    required String ownershipType,
  }) async {
    state = const AsyncValue.loading();
    try {
      print('[MACHINERY CONTROLLER] Creating machinery: $name');
      await _repository.createMachinery(
        name: name,
        type: type,
        registrationNo: registrationNo,
        ownershipType: ownershipType,
      );
      state = const AsyncValue.data(null);
      print('[MACHINERY CONTROLLER] Machinery created successfully');
      return true;
    } catch (e, st) {
      print('[MACHINERY CONTROLLER ERROR] Failed to create machinery: $e');
      print('[MACHINERY CONTROLLER STACK] $st');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> logTimeBased({
    required String projectId,
    required String machineryId,
    required String workActivity,
    required DateTime logDate,
    required String startTime,
    required String endTime,
    required double totalHours,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      print('[MACHINERY CONTROLLER] Logging time-based usage');
      await _repository.logMachineryUsageTimeBased(
        projectId: projectId,
        machineryId: machineryId,
        workActivity: workActivity,
        logDate: logDate,
        startTime: startTime,
        endTime: endTime,
        totalHours: totalHours,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      print('[MACHINERY CONTROLLER] Time-based log saved successfully');
      return true;
    } catch (e, st) {
      print('[MACHINERY CONTROLLER ERROR] Failed to log time-based usage: $e');
      print('[MACHINERY CONTROLLER STACK] $st');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> logUsage({
    required String projectId,
    required String machineryId,
    required String workActivity,
    required DateTime logDate,
    required double startReading,
    required double endReading,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      print('[MACHINERY CONTROLLER] Logging reading-based usage');
      await _repository.logMachineryUsage(
        projectId: projectId,
        machineryId: machineryId,
        workActivity: workActivity,
        logDate: logDate,
        startReading: startReading,
        endReading: endReading,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      print('[MACHINERY CONTROLLER] Reading-based log saved successfully');
      return true;
    } catch (e, st) {
      print(
        '[MACHINERY CONTROLLER ERROR] Failed to log reading-based usage: $e',
      );
      print('[MACHINERY CONTROLLER STACK] $st');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final machineryControllerProvider =
    StateNotifierProvider<MachineryController, AsyncValue<void>>((ref) {
      return MachineryController(ref.watch(machineryRepositoryProvider));
    });
