import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
    final headerTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ) ??
        const TextStyle(fontWeight: FontWeight.bold);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: AppColors.border),
            columnWidths: columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Header Row
              TableRow(
                decoration: const BoxDecoration(color: AppColors.surfaceVariant),
                children: headers
                    .map(
                      (h) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          h,
                          style: headerTextStyle,
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
