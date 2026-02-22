import 'package:flutter/material.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final String receiptId;
  const ReceiptDetailScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Detail')),
      body: Center(child: Text('Receipt ID: $receiptId')),
    );
  }
}
