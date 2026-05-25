import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/stock_item_model.dart';
import '../providers/inventory_provider.dart';

/// Stock list screen for Admin - shows all materials for a project
class StockListScreen extends ConsumerWidget {
  final String projectId;
  final String projectName;

  const StockListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockItemsAsync = ref.watch(stockItemsProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Stock - $projectName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add stock',
            onPressed: () => _showAddStockDialog(context, ref),
          ),
        ],
      ),
      body: stockItemsAsync.when(
        loading: () => const LoadingWidget(message: 'Loading stock...'),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (items) => items.isEmpty
            ? _buildEmptyState(context)
            : _buildStockList(context, ref, items),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'No stock items yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add materials like Cement, Sand, Steel',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList(
    BuildContext context,
    WidgetRef ref,
    List<StockItemModel> items,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(stockItemsProvider(projectId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _StockItemCard(item: item);
        },
      ),
    );
  }

  void _showAddStockDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '0');
    final thresholdController = TextEditingController(text: '10');
    String selectedUnit = 'bags';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Stock Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Material Name',
                  hintText: 'e.g., Cement, Sand, Steel',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Initial Quantity',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items:
                          [
                                'bags',
                                'kg',
                                'tons',
                                'pieces',
                                'liters',
                                'sq.ft',
                                'cu.ft',
                              ]
                              .map(
                                (u) =>
                                    DropdownMenuItem(value: u, child: Text(u)),
                              )
                              .toList(),
                      onChanged: (v) => selectedUnit = v ?? 'bags',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: thresholdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Low Stock Alert Threshold',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              final repository = ref.read(inventoryRepositoryProvider);
              final newItem = StockItemModel(
                id: '',
                projectId: projectId,
                name: nameController.text,
                quantity: double.tryParse(quantityController.text) ?? 0,
                unit: selectedUnit,
                lowStockThreshold: double.tryParse(thresholdController.text),
              );

              await repository.addStockItem(newItem);
              ref.invalidate(stockItemsProvider(projectId));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _StockItemCard extends StatelessWidget {
  final StockItemModel item;

  const _StockItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.stockStatusColor.withValues(alpha: 0.2),
          child: Icon(Icons.inventory, color: item.stockStatusColor),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(item.description ?? 'No description'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item.quantity.toStringAsFixed(1)} ${item.unit}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: item.stockStatusColor,
              ),
            ),
            if (item.isLowStock)
              const Text(
                'LOW STOCK',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
