import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum BillStatus {
  pending('pending'),
  approved('approved'),
  paid('paid'),
  completed('completed'),
  rejected('rejected');

  final String value;
  const BillStatus(this.value);

  static BillStatus fromString(String? status) {
    return BillStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => BillStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case BillStatus.pending:
        return 'Pending';
      case BillStatus.approved:
        return 'Approved';
      case BillStatus.paid:
        return 'Paid';
      case BillStatus.completed:
        return 'Completed';
      case BillStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case BillStatus.pending:
        return AppColors.warning;
      case BillStatus.approved:
        return AppColors.info;
      case BillStatus.paid:
        return AppColors.success;
      case BillStatus.completed:
        return AppColors.success;
      case BillStatus.rejected:
        return AppColors.error;
    }
  }

  bool get isCompleted =>
      this == BillStatus.paid || this == BillStatus.completed;
}

enum BillType {
  workers('workers'),
  materials('materials'),
  transport('transport'),
  equipmentRent('equipment_rent'),
  expense('expense'),
  income('income'),
  invoice('invoice');

  final String value;
  const BillType(this.value);

  static BillType fromString(String? type) {
    return BillType.values.firstWhere(
      (e) => e.value == type,
      orElse: () => BillType.expense,
    );
  }

  String get label {
    switch (this) {
      case BillType.workers:
        return 'Workers';
      case BillType.materials:
        return 'Materials';
      case BillType.transport:
        return 'Transport';
      case BillType.equipmentRent:
        return 'Equipment Rent';
      case BillType.expense:
        return 'Expense';
      case BillType.income:
        return 'Income';
      case BillType.invoice:
        return 'Invoice';
    }
  }
}

enum PaymentType {
  cash('cash'),
  upi('upi'),
  bankTransfer('bank_transfer'),
  cheque('cheque');

  final String value;
  const PaymentType(this.value);

  static PaymentType? fromString(String? type) {
    if (type == null) return null;
    return PaymentType.values.firstWhere(
      (e) => e.value == type,
      orElse: () => PaymentType.cash,
    );
  }

  String get label {
    switch (this) {
      case PaymentType.cash:
        return 'Cash';
      case PaymentType.upi:
        return 'UPI';
      case PaymentType.bankTransfer:
        return 'Bank Transfer';
      case PaymentType.cheque:
        return 'Cheque';
    }
  }
}

enum PaymentStatus {
  needToPay('need_to_pay'),
  advance('advance'),
  halfPaid('half_paid'),
  fullPaid('full_paid');

  final String value;
  const PaymentStatus(this.value);

  static PaymentStatus fromString(String? status) {
    if (status == null) return PaymentStatus.needToPay;
    if (status == 'pending') return PaymentStatus.needToPay;
    if (status == 'will_pay') return PaymentStatus.advance;
    if (status == 'paid') return PaymentStatus.fullPaid;

    return PaymentStatus.values.firstWhere(
      (e) => e.value == status.toLowerCase(),
      orElse: () => PaymentStatus.needToPay,
    );
  }

  String get label {
    switch (this) {
      case PaymentStatus.needToPay:
        return 'Pending';
      case PaymentStatus.advance:
        return 'Will Pay';
      case PaymentStatus.halfPaid:
        return 'Half Paid';
      case PaymentStatus.fullPaid:
        return 'Paid';
    }
  }
}

class BillModel {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final double amount;
  final BillType type;
  final BillStatus status;
  final DateTime billDate;
  final DateTime? dueDate;
  final String? vendorName;
  final String? receiptUrl;
  final String? createdBy;
  final String? raisedBy;
  final String? approvedBy;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final PaymentType? paymentType;
  final PaymentStatus paymentStatus;

  // Joined data (optional)
  final String? projectName;
  final String? createdByName;
  final String? approvedByName;

  const BillModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.amount,
    this.type = BillType.expense,
    this.status = BillStatus.pending,
    required this.billDate,
    this.dueDate,
    this.vendorName,
    this.receiptUrl,
    this.createdBy,
    this.raisedBy,
    this.approvedBy,
    this.createdAt,
    this.approvedAt,
    this.paymentType,
    this.paymentStatus = PaymentStatus.needToPay,
    this.projectName,
    this.createdByName,
    this.approvedByName,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: BillType.fromString(json['bill_type'] as String?),
      status: BillStatus.fromString(json['status'] as String?),
      billDate: DateTime.parse(json['bill_date'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      vendorName: json['vendor_name'] as String?,
      receiptUrl: (json['receipt_url'] ?? json['image_url']) as String?,
      createdBy: json['created_by'] as String?,
      raisedBy: json['raised_by'] as String?,
      approvedBy: json['approved_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      paymentType: PaymentType.fromString(json['payment_type'] as String?),
      paymentStatus: PaymentStatus.fromString(
        json['payment_status'] as String?,
      ),

      projectName: json['project'] != null
          ? json['project']['name'] as String?
          : (json['projects'] != null
                ? json['projects']['name'] as String?
                : null),

      createdByName: json['creator'] != null
          ? json['creator']['full_name'] as String?
          : (json['user_profiles'] != null
                ? json['user_profiles']['full_name'] as String?
                : null),

      approvedByName: json['approver'] != null
          ? json['approver']['full_name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'title': title,
      'description': description,
      'amount': amount,
      'bill_type': type.value,
      'status': status.value,
      'bill_date': billDate.toIso8601String().split('T').first,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'vendor_name': vendorName,
      'receipt_url': receiptUrl,
      'created_by': createdBy,
      'raised_by': raisedBy,
      'approved_by': approvedBy,
      'payment_type': paymentType?.value,
      'payment_status': paymentStatus.value,
    };
  }

  BillModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    double? amount,
    BillType? type,
    BillStatus? status,
    DateTime? billDate,
    DateTime? dueDate,
    String? vendorName,
    String? receiptUrl,
    String? createdBy,
    String? raisedBy,
    String? approvedBy,
    DateTime? createdAt,
    DateTime? approvedAt,
    PaymentType? paymentType,
    PaymentStatus? paymentStatus,
    String? projectName,
    String? createdByName,
    String? approvedByName,
  }) {
    return BillModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      billDate: billDate ?? this.billDate,
      dueDate: dueDate ?? this.dueDate,
      vendorName: vendorName ?? this.vendorName,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdBy: createdBy ?? this.createdBy,
      raisedBy: raisedBy ?? this.raisedBy,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      paymentType: paymentType ?? this.paymentType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      projectName: projectName ?? this.projectName,
      createdByName: createdByName ?? this.createdByName,
      approvedByName: approvedByName ?? this.approvedByName,
    );
  }
}
