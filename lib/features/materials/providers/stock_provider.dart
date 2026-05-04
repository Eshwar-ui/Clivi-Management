import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_client.dart';
import '../data/models/stock_item.dart';
import '../data/models/material_log.dart';
import '../data/repositories/stock_repository.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository(supabase);
});

// Stock Items Stream
final stockItemsStreamProvider = StreamProvider.family<List<StockItem>, String>(
  (ref, projectId) {
    final repo = ref.watch(stockRepositoryProvider);
    return repo.streamStockItemsByProject(projectId);
  },
);

// Logs Stream (Optional, if we add stream method to repo for logs too. Repo currently has getMaterialLogsByProject Future. I should add stream there too if needed. For now Future is fine for logs list, but stream is better. Let's stick to Future or Stream. StockItems HAS stream in repo).
// The repo has:
// Stream<List<StockItem>> streamStockItemsByProject(String projectId)
// Future<List<MaterialLog>> getMaterialLogsByProject(String projectId)

// I will use Future for logs for now, or add Stream if needed.
final materialLogsProvider = FutureProvider.family<List<MaterialLog>, String>((
  ref,
  projectId,
) async {
  final repo = ref.watch(stockRepositoryProvider);
  return repo.getMaterialLogsByProject(projectId);
});

// Controller
class StockController extends StateNotifier<AsyncValue<void>> {
  final StockRepository _repository;

  StockController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> logInward({
    required String projectId,
    // itemId is not needed as repo handles it by name
    required double quantity,
    required String stockItemName,
    required String stockItemUnit,
    String? stockItemGrade,
    String? activity,
    String? notes,
    required String supplierId,
    required String paymentType,
    required double billAmount,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.logMaterialInward(
        projectId: projectId,
        quantity: quantity,
        stockItemName: stockItemName,
        stockItemUnit: stockItemUnit,
        stockItemGrade: stockItemGrade,
        activity: activity,
        notes: notes,
        supplierId: supplierId,
        paymentType: paymentType,
        billAmount: billAmount,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> logOutward({
    required String projectId,
    required String itemId,
    required double quantity,
    String? activity,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.logMaterialOutward(
        projectId: projectId,
        itemId: itemId,
        quantity: quantity,
        activity: activity,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final stockControllerProvider =
    StateNotifierProvider<StockController, AsyncValue<void>>((ref) {
      return StockController(ref.watch(stockRepositoryProvider));
    });

// Dynamic Stock Balance Provider for summaries and consumption
final stockBalanceProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, projectId) {
      return ref.watch(stockRepositoryProvider).getStockBalance(projectId);
    });
