import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../providers/stock_provider.dart';
import '../data/models/stock_item.dart';
import '../data/models/material_log.dart';

class MaterialsTabScreen extends ConsumerStatefulWidget {
  final String projectId;
  const MaterialsTabScreen({super.key, required this.projectId});

  @override
  ConsumerState<MaterialsTabScreen> createState() => _MaterialsTabScreenState();
}

class _MaterialsTabScreenState extends ConsumerState<MaterialsTabScreen> {
  bool _showByVendor = false;

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref
        .watch(stockRepositoryProvider)
        .getStockItemsByProject(widget.projectId);
    final logsAsync = ref
        .watch(stockRepositoryProvider)
        .getMaterialLogsByProject(widget.projectId);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Material Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: FutureBuilder(
        future: Future.wait([stockAsync, logsAsync]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppErrorWidget(
              message: 'Error loading data: ${snapshot.error}',
            );
          }

          final stockItems = snapshot.data![0] as List<StockItem>;
          final logs = snapshot.data![1] as List<MaterialLog>;

          if (stockItems.isEmpty) {
            return const Center(child: Text('No materials found'));
          }

          // 1. Group Logic
          final Map<String, List<StockItem>> groupedMaterials = {};
          for (var item in stockItems) {
            final name = item.name.trim().toLowerCase();
            // Store with original casing key if preferred, but for grouping use normalized
            // We'll use the capitalized name from the first item as the display key
            // Ideally finding the key first
            String? key;
            for (var k in groupedMaterials.keys) {
              if (k.toLowerCase() == name) {
                key = k;
                break;
              }
            }
            key ??= item.name; // Use this item's name as new key

            if (!groupedMaterials.containsKey(key)) {
              groupedMaterials[key] = [];
            }
            groupedMaterials[key]!.add(item);
          }

          // Vendor totals for this project (inward only)
          final Map<String, _VendorTotal> vendorTotals = {};
          for (final log in logs.where(
            (l) => l.logType == 'inward' && l.supplier != null,
          )) {
            final key = log.supplier!.id;
            vendorTotals.putIfAbsent(
              key,
              () => _VendorTotal(
                supplierId: key,
                supplierName: log.supplier!.name,
              ),
            );
            vendorTotals[key]!.totalQuantity += log.quantity;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('By Material')),
                    ButtonSegment(value: true, label: Text('By Vendor')),
                  ],
                  selected: {_showByVendor},
                  onSelectionChanged: (v) =>
                      setState(() => _showByVendor = v.first),
                ),
              ),
              Expanded(
                child: _showByVendor
                    ? ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: vendorTotals.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final vendor = vendorTotals.values.elementAt(index);
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(vendor.supplierName),
                              subtitle: const Text('Inward quantity'),
                              trailing: Text(
                                vendor.totalQuantity.toStringAsFixed(2),
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedMaterials.keys.length,
                        itemBuilder: (context, index) {
                          final materialName = groupedMaterials.keys.elementAt(
                            index,
                          );
                          final items = groupedMaterials[materialName]!;

                          // Calculate Aggregates
                          double totalQuantity = 0;
                          double totalConsumed = 0;
                          double totalCost = 0;

                          // Determine primary unit (first item's unit) - simplistic
                          final unit = items.first.unit;

                          for (var item in items) {
                            totalQuantity +=
                                item.quantity; // This is current stock

                            // Calculate consumption and receipts from logs for this item ID
                            final itemLogs = logs.where(
                              (l) => l.itemId == item.id,
                            );
                            for (var log in itemLogs) {
                              if (log.logType == 'inward') {
                                if (log.billAmount != null) {
                                  totalCost += log.billAmount!;
                                }
                              }
                              if (log.logType == 'outward') {
                                totalConsumed += log.quantity;
                              }
                            }
                          }

                          return _MaterialGroupCard(
                            name: materialName,
                            totalCurrentStock: totalQuantity,
                            totalConsumed: totalConsumed,
                            totalCost: totalCost,
                            unit: unit,
                            variants: items,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MaterialGroupCard extends StatefulWidget {
  final String name;
  final double totalCurrentStock;
  final double totalConsumed;
  final double totalCost;
  final String unit;
  final List<StockItem> variants;

  const _MaterialGroupCard({
    required this.name,
    required this.totalCurrentStock,
    required this.totalConsumed,
    required this.totalCost,
    required this.unit,
    required this.variants,
  });

  @override
  State<_MaterialGroupCard> createState() => _MaterialGroupCardState();
}

class _VendorTotal {
  final String supplierId;
  final String supplierName;
  double totalQuantity;

  _VendorTotal({
    required this.supplierId,
    required this.supplierName,
  }) : totalQuantity = 0;
}

class _MaterialGroupCardState extends State<_MaterialGroupCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          // Header (Always Visible)
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
              bottom: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${widget.variants.length} Variants',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${widget.totalCost.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text(
                            'Total Cost',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quick Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatItem(
                        label: 'Net Stock',
                        value: '${widget.totalCurrentStock} ${widget.unit}',
                      ),
                      _StatItem(
                        label: 'Total Consumed',
                        value: '${widget.totalConsumed} ${widget.unit}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Details (Variants)
          if (_expanded)
            Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  const Text(
                    'VARIANTS / GRADES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.variants.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.name +
                                (item.grade != null && item.grade!.isNotEmpty
                                    ? ' (${item.grade})'
                                    : ''),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${item.quantity} ${item.unit}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
