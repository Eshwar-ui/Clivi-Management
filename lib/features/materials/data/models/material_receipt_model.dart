import 'package:freezed_annotation/freezed_annotation.dart';

part 'material_receipt_model.freezed.dart';
part 'material_receipt_model.g.dart';

@freezed
class MaterialReceiptModel with _$MaterialReceiptModel {
  const factory MaterialReceiptModel({
    required String id,
    required String projectId,
    required String receiptNumber,
    required DateTime receiptDate,
    String? vendorId,
    String? vendorNameSnapshot,
    String? invoiceNumber,
    DateTime? invoiceDate,
    double? invoiceAmount,
    @Default(0) int totalItems,
    @Default(0) double subtotal,
    @Default(0) double totalGst,
    @Default(0) double grandTotal,
    String? attachmentUrl,
    String? attachmentType,
    @Default('pending') String paymentStatus,
    String? paymentNotes,
    @Default('draft') String status,
    String? notes,
    required String createdBy,
    required DateTime createdAt,
    DateTime? updatedAt,
    String? confirmedBy,
    DateTime? confirmedAt,
    @Default([]) List<MaterialReceiptItemModel> items,
  }) = _MaterialReceiptModel;

  factory MaterialReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$MaterialReceiptModelFromJson(json);
}

@freezed
class MaterialReceiptItemModel with _$MaterialReceiptItemModel {
  const factory MaterialReceiptItemModel({
    String? id,
    String? receiptId,
    String? projectId,
    String? materialId,
    required String materialName,
    String? materialCategory,
    String? brandCompany,
    required double quantity,
    required String unit,
    required double rate,
    double? amount,
    @Default(0) double gstPercent,
    double? gstAmount,
    double? totalAmount,
    String? itemNotes,
  }) = _MaterialReceiptItemModel;

  factory MaterialReceiptItemModel.fromJson(Map<String, dynamic> json) =>
      _$MaterialReceiptItemModelFromJson(json);
}
