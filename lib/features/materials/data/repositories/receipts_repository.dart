import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/material_receipt_model.dart';

class ReceiptsRepository {
  final SupabaseClient _client;

  ReceiptsRepository(this._client);

  /// Generate receipt number for a project
  Future<String> generateReceiptNumber(String projectId) async {
    final response = await _client.rpc(
      'generate_receipt_number',
      params: {'p_project_id': projectId},
    );
    return response as String;
  }

  /// Create receipt with items (bulk add)
  Future<MaterialReceiptModel> createReceiptWithItems({
    required String projectId,
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
    // 1. Generate receipt number
    final receiptNumber = await generateReceiptNumber(projectId);

    // 2. Create parent receipt
    final receiptData = {
      'project_id': projectId,
      'receipt_number': receiptNumber,
      'receipt_date': receiptDate.toIso8601String().split('T')[0],
      'vendor_id': vendorId,
      'vendor_name_snapshot': vendorName,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate?.toIso8601String().split('T')[0],
      'invoice_amount': invoiceAmount,
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentType,
      'notes': notes,
      'status': 'confirmed', // Auto-confirm or use 'draft'
      'created_by': _client.auth.currentUser!.id,
    };

    final receiptResponse = await _client
        .from('material_receipts')
        .insert(receiptData)
        .select()
        .single();

    final receiptId = receiptResponse['id'] as String;

    // 3. Create child items
    final itemsData = items
        .map(
          (item) => {
            'receipt_id': receiptId,
            // project_id is auto-set by trigger or needs to be passed if no trigger
            'project_id': projectId,
            'material_id': item.materialId,
            'material_name': item.materialName,
            'material_category': item.materialCategory,
            'brand_company': item.brandCompany,
            'quantity': item.quantity,
            'unit': item.unit,
            'rate': item.rate,
            'gst_percent': item.gstPercent,
            'item_notes': item.itemNotes,
          },
        )
        .toList();

    await _client.from('material_receipt_items').insert(itemsData);

    // 4. Fetch and return complete receipt
    return getReceiptById(receiptId);
  }

  /// Get receipt by ID with items
  Future<MaterialReceiptModel> getReceiptById(String receiptId) async {
    final response = await _client
        .from('material_receipts')
        .select('*, items:material_receipt_items(*)')
        .eq('id', receiptId)
        .single();
    return MaterialReceiptModel.fromJson(response);
  }

  /// Get receipts for a project
  Future<List<MaterialReceiptModel>> getProjectReceipts({
    required String projectId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client
        .from('material_receipts')
        .select('*, items:material_receipt_items(*)')
        .eq('project_id', projectId)
        .filter('deleted_at', 'is', 'null');

    if (fromDate != null) {
      query = query.gte(
        'receipt_date',
        fromDate.toIso8601String().split('T')[0],
      );
    }
    if (toDate != null) {
      query = query.lte('receipt_date', toDate.toIso8601String().split('T')[0]);
    }

    final response = await query
        .order('receipt_date', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List)
        .map((e) => MaterialReceiptModel.fromJson(e))
        .toList();
  }

  /// Upload attachment
  Future<String> uploadAttachment({
    required String projectId,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    // Fixed string interpolation from user code
    final path =
        '$projectId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage
        .from('material-receipts')
        .uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(contentType: mimeType),
        );

    return _client.storage.from('material-receipts').getPublicUrl(path);
  }
}
