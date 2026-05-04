import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_balance_model.freezed.dart';
part 'stock_balance_model.g.dart';

@freezed
class StockBalanceModel with _$StockBalanceModel {
  const factory StockBalanceModel({
    required String projectId,
    required String projectName,
    String? materialId,
    required String materialName,
    String? materialCategory,
    required String unit,
    required double totalReceived,
    required double totalConsumed,
    required double balance,
    required double totalValue,
    required double consumedPercentage,
  }) = _StockBalanceModel;

  factory StockBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$StockBalanceModelFromJson(json);
}
