// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_receipt_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MaterialReceiptModelImpl _$$MaterialReceiptModelImplFromJson(
  Map<String, dynamic> json,
) => _$MaterialReceiptModelImpl(
  id: json['id'] as String,
  projectId: json['projectId'] as String,
  receiptNumber: json['receiptNumber'] as String,
  receiptDate: DateTime.parse(json['receiptDate'] as String),
  vendorId: json['vendorId'] as String?,
  vendorNameSnapshot: json['vendorNameSnapshot'] as String?,
  invoiceNumber: json['invoiceNumber'] as String?,
  invoiceDate: json['invoiceDate'] == null
      ? null
      : DateTime.parse(json['invoiceDate'] as String),
  invoiceAmount: (json['invoiceAmount'] as num?)?.toDouble(),
  totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
  subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
  totalGst: (json['totalGst'] as num?)?.toDouble() ?? 0,
  grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
  attachmentUrl: json['attachmentUrl'] as String?,
  attachmentType: json['attachmentType'] as String?,
  paymentStatus: json['paymentStatus'] as String? ?? 'pending',
  paymentNotes: json['paymentNotes'] as String?,
  status: json['status'] as String? ?? 'draft',
  notes: json['notes'] as String?,
  createdBy: json['createdBy'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  confirmedBy: json['confirmedBy'] as String?,
  confirmedAt: json['confirmedAt'] == null
      ? null
      : DateTime.parse(json['confirmedAt'] as String),
  items:
      (json['items'] as List<dynamic>?)
          ?.map(
            (e) => MaterialReceiptItemModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$$MaterialReceiptModelImplToJson(
  _$MaterialReceiptModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'projectId': instance.projectId,
  'receiptNumber': instance.receiptNumber,
  'receiptDate': instance.receiptDate.toIso8601String(),
  'vendorId': instance.vendorId,
  'vendorNameSnapshot': instance.vendorNameSnapshot,
  'invoiceNumber': instance.invoiceNumber,
  'invoiceDate': instance.invoiceDate?.toIso8601String(),
  'invoiceAmount': instance.invoiceAmount,
  'totalItems': instance.totalItems,
  'subtotal': instance.subtotal,
  'totalGst': instance.totalGst,
  'grandTotal': instance.grandTotal,
  'attachmentUrl': instance.attachmentUrl,
  'attachmentType': instance.attachmentType,
  'paymentStatus': instance.paymentStatus,
  'paymentNotes': instance.paymentNotes,
  'status': instance.status,
  'notes': instance.notes,
  'createdBy': instance.createdBy,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'confirmedBy': instance.confirmedBy,
  'confirmedAt': instance.confirmedAt?.toIso8601String(),
  'items': instance.items,
};

_$MaterialReceiptItemModelImpl _$$MaterialReceiptItemModelImplFromJson(
  Map<String, dynamic> json,
) => _$MaterialReceiptItemModelImpl(
  id: json['id'] as String?,
  receiptId: json['receiptId'] as String?,
  projectId: json['projectId'] as String?,
  materialId: json['materialId'] as String?,
  materialName: json['materialName'] as String,
  materialCategory: json['materialCategory'] as String?,
  brandCompany: json['brandCompany'] as String?,
  quantity: (json['quantity'] as num).toDouble(),
  unit: json['unit'] as String,
  rate: (json['rate'] as num).toDouble(),
  amount: (json['amount'] as num?)?.toDouble(),
  gstPercent: (json['gstPercent'] as num?)?.toDouble() ?? 0,
  gstAmount: (json['gstAmount'] as num?)?.toDouble(),
  totalAmount: (json['totalAmount'] as num?)?.toDouble(),
  itemNotes: json['itemNotes'] as String?,
);

Map<String, dynamic> _$$MaterialReceiptItemModelImplToJson(
  _$MaterialReceiptItemModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'receiptId': instance.receiptId,
  'projectId': instance.projectId,
  'materialId': instance.materialId,
  'materialName': instance.materialName,
  'materialCategory': instance.materialCategory,
  'brandCompany': instance.brandCompany,
  'quantity': instance.quantity,
  'unit': instance.unit,
  'rate': instance.rate,
  'amount': instance.amount,
  'gstPercent': instance.gstPercent,
  'gstAmount': instance.gstAmount,
  'totalAmount': instance.totalAmount,
  'itemNotes': instance.itemNotes,
};
