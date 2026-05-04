import 'package:flutter/material.dart';

/// Stock item model - represents a material type (Cement, Sand, Steel, etc.)
class StockItemModel {
  final String id;
  final String projectId;
  final String name;
  final String? description;
  final double quantity;
  final String unit;
  final double? lowStockThreshold;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StockItemModel({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    required this.quantity,
    this.unit = 'units',
    this.lowStockThreshold,
    this.createdAt,
    this.updatedAt,
  });

  factory StockItemModel.fromJson(Map<String, dynamic> json) {
    return StockItemModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      quantity: double.tryParse(json['quantity'].toString()) ?? 0,
      unit: json['unit'] as String? ?? 'units',
      lowStockThreshold: json['low_stock_threshold'] != null
          ? double.tryParse(json['low_stock_threshold'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'low_stock_threshold': lowStockThreshold,
    };
  }

  bool get isLowStock =>
      lowStockThreshold != null && quantity <= lowStockThreshold!;

  Color get stockStatusColor {
    if (isLowStock) return Colors.red;
    if (lowStockThreshold != null && quantity <= lowStockThreshold! * 1.5) {
      return Colors.orange;
    }
    return Colors.green;
  }

  StockItemModel copyWith({
    String? id,
    String? projectId,
    String? name,
    String? description,
    double? quantity,
    String? unit,
    double? lowStockThreshold,
  }) {
    return StockItemModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() =>
      'StockItemModel(id: $id, name: $name, qty: $quantity $unit)';
}
