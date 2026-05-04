// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_balance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StockBalanceModelImpl _$$StockBalanceModelImplFromJson(
  Map<String, dynamic> json,
) => _$StockBalanceModelImpl(
  projectId: json['projectId'] as String,
  projectName: json['projectName'] as String,
  materialId: json['materialId'] as String?,
  materialName: json['materialName'] as String,
  materialCategory: json['materialCategory'] as String?,
  unit: json['unit'] as String,
  totalReceived: (json['totalReceived'] as num).toDouble(),
  totalConsumed: (json['totalConsumed'] as num).toDouble(),
  balance: (json['balance'] as num).toDouble(),
  totalValue: (json['totalValue'] as num).toDouble(),
  consumedPercentage: (json['consumedPercentage'] as num).toDouble(),
);

Map<String, dynamic> _$$StockBalanceModelImplToJson(
  _$StockBalanceModelImpl instance,
) => <String, dynamic>{
  'projectId': instance.projectId,
  'projectName': instance.projectName,
  'materialId': instance.materialId,
  'materialName': instance.materialName,
  'materialCategory': instance.materialCategory,
  'unit': instance.unit,
  'totalReceived': instance.totalReceived,
  'totalConsumed': instance.totalConsumed,
  'balance': instance.balance,
  'totalValue': instance.totalValue,
  'consumedPercentage': instance.consumedPercentage,
};
