import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/bill_model.dart';
import '../data/repositories/bill_repository.dart';

// ============================================================
// REPOSITORY PROVIDER
// ============================================================

final billRepositoryProvider = Provider<BillRepository>((ref) {
  return BillRepository();
});

// ============================================================
// STREAMS (READ)
// ============================================================

/// Real-time stream of bills for a specific project
final billsStreamProvider = StreamProvider.family<List<BillModel>, String>((ref, projectId) {
  final repository = ref.watch(billRepositoryProvider);
  return repository.streamBillsByProject(projectId);
});

/// Baseline fetch of bills (non-realtime)
final billsProvider = FutureProvider.family<List<BillModel>, String>((ref, projectId) {
  final repository = ref.watch(billRepositoryProvider);
  return repository.fetchBills(projectId);
});

/// Combined provider: initial fetch + realtime overlay
final billsCombinedProvider = Provider.family<AsyncValue<List<BillModel>>, String>((ref, projectId) {
  final fetchAsync = ref.watch(billsProvider(projectId));
  final streamAsync = ref.watch(billsStreamProvider(projectId));

  return fetchAsync.when(
    data: (fetched) {
      return streamAsync.when(
        data: (streamed) {
          // Merge by id (upsert) using streamed as latest
          final byId = {for (var b in fetched) b.id: b};
          for (final b in streamed) {
            final existing = byId[b.id];
            byId[b.id] = existing == null ? b : _mergeBillSnapshot(existing, b);
          }
          return AsyncValue.data(byId.values.toList()
            ..sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))));
        },
        loading: () => AsyncValue.data(fetched),
        error: (e, st) => AsyncValue.error(e, st),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Real-time stream of bills for dashboard (all accessible or only current user's raised bills)
final dashboardBillsStreamProvider = StreamProvider.family<List<BillModel>, bool>((ref, onlyRaisedByCurrentUser) {
  final repository = ref.watch(billRepositoryProvider);
  return repository.streamBillsForDashboard(
    onlyRaisedByCurrentUser: onlyRaisedByCurrentUser,
  );
});

/// Baseline fetch for dashboard bills
final dashboardBillsProvider = FutureProvider.family<List<BillModel>, bool>((ref, onlyRaisedByCurrentUser) {
  final repository = ref.watch(billRepositoryProvider);
  return repository.fetchBillsForDashboard(
    onlyRaisedByCurrentUser: onlyRaisedByCurrentUser,
  );
});

/// Combined provider for dashboard bills
final dashboardBillsCombinedProvider = Provider.family<AsyncValue<List<BillModel>>, bool>((ref, onlyRaisedByCurrentUser) {
  final fetchAsync = ref.watch(dashboardBillsProvider(onlyRaisedByCurrentUser));
  final streamAsync = ref.watch(dashboardBillsStreamProvider(onlyRaisedByCurrentUser));

  return fetchAsync.when(
    data: (fetched) {
      return streamAsync.when(
        data: (streamed) {
          final byId = {for (var b in fetched) b.id: b};
          for (final b in streamed) {
            final existing = byId[b.id];
            byId[b.id] = existing == null ? b : _mergeBillSnapshot(existing, b);
          }
          final items = byId.values.toList()
            ..sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
          return AsyncValue.data(items);
        },
        loading: () => AsyncValue.data(fetched),
        error: (e, st) => AsyncValue.error(e, st),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Fetch pending bills with pagination
final paginatedPendingBillsProvider = FutureProvider.family<List<BillModel>, ({String projectId, int offset, int limit})>((ref, params) {
  final repository = ref.watch(billRepositoryProvider);
  return repository.getPendingBills(
    projectId: params.projectId,
    offset: params.offset,
    limit: params.limit,
  );
});

// ============================================================
// CONTROLLER (WRITE)
// ============================================================

class BillController extends StateNotifier<AsyncValue<void>> {
  final BillRepository _repository;

  BillController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> createBill({
    required String projectId,
    required String title,
    required double amount,
    required String billType,
    String? description,
    String? vendorName,
    String? paymentType,
    String? paymentStatus,
    List<int>? receiptBytes,
    String? receiptName,
    DateTime? billDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createBill(
        projectId: projectId,
        title: title,
        amount: amount,
        billType: billType,
        description: description,
        vendorName: vendorName,
        paymentType: paymentType,
        paymentStatus: paymentStatus,
        receiptBytes: receiptBytes,
        receiptName: receiptName,
        billDate: billDate,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> approveBill(String billId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.approveBill(billId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rejectBill(String billId, {String? reason}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.rejectBill(billId, reason: reason);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> deleteBill(String billId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteBill(billId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateBill({
    required String billId,
    required Map<String, dynamic> updates,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateBill(billId, updates);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateBillApproval({
    required String billId,
    required PaymentStatus paymentStatus,
    required bool markCompleted,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateBillApproval(
        billId: billId,
        paymentStatus: paymentStatus,
        markCompleted: markCompleted,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

// Controller Provider
final billControllerProvider = StateNotifierProvider<BillController, AsyncValue<void>>((ref) {
  return BillController(ref.watch(billRepositoryProvider));
});

BillModel _mergeBillSnapshot(BillModel fetched, BillModel streamed) {
  return streamed.copyWith(
    projectName: streamed.projectName ?? fetched.projectName,
    createdByName: streamed.createdByName ?? fetched.createdByName,
    approvedByName: streamed.approvedByName ?? fetched.approvedByName,
  );
}
