class VendorPayment {
  final String id;
  final String? receiptId;
  final String vendorId;
  final DateTime paymentDate;
  final double paymentAmount;
  final String?
  paymentMethod; // 'cash', 'cheque', 'upi', 'bank_transfer', 'other'
  final String? transactionReference;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  const VendorPayment({
    required this.id,
    this.receiptId,
    required this.vendorId,
    required this.paymentDate,
    required this.paymentAmount,
    this.paymentMethod,
    this.transactionReference,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  factory VendorPayment.fromJson(Map<String, dynamic> json) {
    return VendorPayment(
      id: json['id'] as String,
      receiptId: json['receipt_id'] as String?,
      vendorId: json['vendor_id'] as String,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      paymentAmount: (json['payment_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String?,
      transactionReference: json['transaction_reference'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receipt_id': receiptId,
      'vendor_id': vendorId,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'payment_amount': paymentAmount,
      'payment_method': paymentMethod,
      'transaction_reference': transactionReference,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
