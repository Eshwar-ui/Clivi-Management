import 'package:flutter/material.dart';

class BulkEntryTable<T> extends StatelessWidget {
  final List<String> headers;
  final List<T> items;
  final TableRow Function(BuildContext context, T item, int index) rowBuilder;
  final VoidCallback? onAddRow;
  final Map<int, TableColumnWidth>? columnWidths;

  const BulkEntryTable({
    super.key,
    required this.headers,
    required this.items,
    required this.rowBuilder,
    this.onAddRow,
    this.columnWidths,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          columnWidths: columnWidths,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Header Row
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: headers
                  .map(
                    (h) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        h,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                  .toList(),
            ),
            // Data Rows
            ...items.asMap().entries.map((entry) {
              return rowBuilder(context, entry.value, entry.key);
            }),
          ],
        ),
        if (onAddRow != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton.icon(
              onPressed: onAddRow,
              icon: const Icon(Icons.add),
              label: const Text('Add Row'),
            ),
          ),
      ],
    );
  }
}
