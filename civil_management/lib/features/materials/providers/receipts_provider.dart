import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/providers/current_project_provider.dart';
import '../../materials/data/models/material_receipt_model.dart';
import '../../materials/data/models/stock_balance_model.dart';
import 'repository_providers.dart';

part 'receipts_provider.g.dart';

@riverpod
class ProjectReceipts extends _$ProjectReceipts {
  @override
  Future<List<MaterialReceiptModel>> build() async {
    final projectId = ref.watch(requireCurrentProjectIdProvider);
    final repository = ref.read(receiptsRepositoryProvider);
    return repository.getProjectReceipts(projectId: projectId);
  }

  Future<void> addReceipt({
    required DateTime receiptDate,
    String? vendorId,
    String? vendorName,
    String? invoiceNumber,
    DateTime? invoiceDate,
    double? invoiceAmount,
    String? attachmentUrl,
    String? attachmentType,
    String? notes,
    required List<MaterialReceiptItemModel> items,
  }) async {
    final projectId = ref.read(requireCurrentProjectIdProvider);
    final repository = ref.read(receiptsRepositoryProvider);

    await repository.createReceiptWithItems(
      projectId: projectId,
      receiptDate: receiptDate,
      vendorId: vendorId,
      vendorName: vendorName,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      invoiceAmount: invoiceAmount,
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
      notes: notes,
      items: items,
    );

    // Invalidate to refresh
    ref.invalidateSelf();
    // Also invalidate stock balance
    ref.invalidate(projectStockBalanceProvider);
  }
}

@riverpod
Future<List<StockBalanceModel>> projectStockBalance(
  ProjectStockBalanceRef ref,
) async {
  final projectId = ref.watch(requireCurrentProjectIdProvider);
  final repository = ref.read(materialsRepositoryProvider);
  return repository.getProjectStockBalance(projectId);
}
