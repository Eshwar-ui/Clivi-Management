import 'package:flutter/material.dart';

class StockLedgerScreen extends StatelessWidget {
  const StockLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Ledger')),
      body: const Center(child: Text('Stock Ledger View')),
    );
  }
}
