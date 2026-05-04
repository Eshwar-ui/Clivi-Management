import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/ui/responsive_scaffold.dart';

import '../../../core/widgets/loading_widget.dart';
import '../data/models/stock_item_model.dart';
import '../data/models/material_log_model.dart';
import '../data/models/supplier_model.dart';
import '../providers/inventory_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// Daily Material Log screen with Inward/Outward tabs for Site Managers
class DailyMaterialLogScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;

  const DailyMaterialLogScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<DailyMaterialLogScreen> createState() =>
      _DailyMaterialLogScreenState();
}

class _DailyMaterialLogScreenState extends ConsumerState<DailyMaterialLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Material Log - ${widget.projectName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.arrow_downward), text: 'Received'),
            Tab(icon: Icon(Icons.arrow_upward), text: 'Used'),
          ],
        ),
      ),
      fab: FloatingActionButton.extended(
        onPressed: () => _showAddLogDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
      builder: (context, r) {
        return Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _LogListTab(
                    projectId: widget.projectId,
                    logType: LogType.inward,
                  ),
                  _LogListTab(
                    projectId: widget.projectId,
                    logType: LogType.outward,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddLogDialog(BuildContext context) {
    final stockItemsAsync = ref.read(stockItemsProvider(widget.projectId));

    stockItemsAsync.whenData((items) {
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No stock items available. Ask admin to add materials first.',
            ),
          ),
        );
        return;
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          child: _AddLogBottomSheet(
            projectId: widget.projectId,
            stockItems: stockItemsAsync.value ?? [],
            initialLogType: _tabController.index == 0
                ? LogType.inward
                : LogType.outward,
            onAdded: () {
              ref.invalidate(inwardLogsProvider(widget.projectId));
              ref.invalidate(outwardLogsProvider(widget.projectId));
              ref.invalidate(stockItemsProvider(widget.projectId));
            },
          ),
        ),
      ),
    );
  }
}

class _SupplierPicker extends ConsumerWidget {
  final void Function(SupplierModel?) onSelected;

  const _SupplierPicker({required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersProvider);

    return suppliersAsync.when(
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text('Failed to load vendors: $e')),
        ],
      ),
      data: (suppliers) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<SupplierModel>(
              decoration: const InputDecoration(
                labelText: 'Vendor (optional)',
                border: OutlineInputBorder(),
              ),
              items: suppliers
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: onSelected,
            ),
            TextButton.icon(
              onPressed: () => _showAddSupplierDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add new vendor'),
            ),
          ],
        );
      },
    );
  }

  void _showAddSupplierDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Vendor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                await ref
                    .read(inventoryRepositoryProvider)
                    .addSupplier(
                      SupplierModel(
                        id: '',
                        name: name,
                        phone: phoneController.text.trim().isEmpty
                            ? null
                            : phoneController.text.trim(),
                        email: emailController.text.trim().isEmpty
                            ? null
                            : emailController.text.trim(),
                        contactPerson: null,
                        address: null,
                        category: null,
                        notes: null,
                        isActive: true,
                      ),
                    );
                ref.invalidate(suppliersProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed to add vendor: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _LogListTab extends ConsumerWidget {
  final String projectId;
  final LogType logType;

  const _LogListTab({required this.projectId, required this.logType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = logType == LogType.inward
        ? ref.watch(inwardLogsProvider(projectId))
        : ref.watch(outwardLogsProvider(projectId));

    return logsAsync.when(
      loading: () => const LoadingWidget(message: 'Loading logs...'),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (logs) => logs.isEmpty
          ? _buildEmptyState(context)
          : _buildLogList(context, ref, logs),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            logType == LogType.inward
                ? Icons.inbox_outlined
                : Icons.outbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            logType == LogType.inward
                ? 'No materials received yet'
                : 'No materials used yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(
    BuildContext context,
    WidgetRef ref,
    List<MaterialLogModel> logs,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        if (logType == LogType.inward) {
          ref.invalidate(inwardLogsProvider(projectId));
        } else {
          ref.invalidate(outwardLogsProvider(projectId));
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return _MaterialLogCard(
            log: log,
            onDeleted: () {
              if (logType == LogType.inward) {
                ref.invalidate(inwardLogsProvider(projectId));
              } else {
                ref.invalidate(outwardLogsProvider(projectId));
              }
              ref.invalidate(stockItemsProvider(projectId));
            },
          );
        },
      ),
    );
  }
}

class _MaterialLogCard extends ConsumerWidget {
  final MaterialLogModel log;
  final VoidCallback onDeleted;

  const _MaterialLogCard({required this.log, required this.onDeleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final role = ref.read(userRoleProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: log.logType == LogType.inward
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log.logType.displayName,
                    style: TextStyle(
                      color: log.logType == LogType.inward
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.itemName ?? 'Unknown Item',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '${log.quantity.toStringAsFixed(1)} ${log.itemUnit ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    final noteController = TextEditingController();
                    final requireNote = role == UserRole.siteManager;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Material Log'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('This will remove the log entry.'),
                            const SizedBox(height: 12),
                            TextField(
                              controller: noteController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText:
                                    'Note ${requireNote ? "*" : "(optional)"}',
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              if (requireNote &&
                                  noteController.text.trim().isEmpty) {
                                return;
                              }
                              Navigator.pop(ctx, true);
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref
                          .read(inventoryRepositoryProvider)
                          .deleteMaterialLog(
                            logId: log.id,
                            projectId: log.projectId,
                            note: noteController.text.trim().isEmpty
                                ? null
                                : noteController.text.trim(),
                          );
                      onDeleted();
                    }
                  },
                ),
              ],
            ),
            if (log.activity != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.construction, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    log.activity!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              log.loggedAt != null
                  ? dateFormat.format(log.loggedAt!)
                  : 'Unknown date',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            if (log.notes != null && log.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                log.notes!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddLogBottomSheet extends ConsumerStatefulWidget {
  final String projectId;
  final List<StockItemModel> stockItems;
  final LogType initialLogType;
  final VoidCallback onAdded;

  const _AddLogBottomSheet({
    required this.projectId,
    required this.stockItems,
    required this.initialLogType,
    required this.onAdded,
  });

  @override
  ConsumerState<_AddLogBottomSheet> createState() => _AddLogBottomSheetState();
}

class _AddLogBottomSheetState extends ConsumerState<_AddLogBottomSheet> {
  late LogType _selectedLogType;
  late List<StockItemModel> _items;
  StockItemModel? _selectedItem;
  final _quantityController = TextEditingController();
  final _amountController = TextEditingController();
  final _activityController = TextEditingController();
  final _notesController = TextEditingController();
  String? _paymentType;
  SupplierModel? _selectedSupplier;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.stockItems);
    _selectedLogType = widget.initialLogType;
    _selectedItem = _items.isNotEmpty ? _items.first : null;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _amountController.dispose();
    _activityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Material Log',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Log Type Toggle
            SegmentedButton<LogType>(
              segments: const [
                ButtonSegment(value: LogType.inward, label: Text('Received')),
                ButtonSegment(value: LogType.outward, label: Text('Used')),
              ],
              selected: {_selectedLogType},
              onSelectionChanged: (v) =>
                  setState(() => _selectedLogType = v.first),
            ),
            const SizedBox(height: 16),

            // Material Selection
            DropdownButtonFormField<StockItemModel>(
              initialValue: _selectedItem,
              decoration: const InputDecoration(
                labelText: 'Select Material',
                border: OutlineInputBorder(),
              ),
              items: _items
                  .where(
                    (item) => _selectedLogType == LogType.inward
                        ? true
                        : item.quantity > 0,
                  )
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        [
                          item.name,
                          if (item.description != null &&
                              item.description!.isNotEmpty)
                            '• ${item.description}',
                          '(${item.quantity} ${item.unit})',
                        ].join(' '),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedItem = v),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add new material'),
                onPressed: _showAddMaterialDialog,
              ),
            ),

            // Supplier (for inward)
            if (_selectedLogType == LogType.inward) ...[
              _SupplierPicker(
                onSelected: (s) => setState(() => _selectedSupplier = s),
              ),
              const SizedBox(height: 16),
            ],

            // Quantity
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: const OutlineInputBorder(),
                suffixText: _selectedItem?.unit ?? '',
              ),
            ),
            const SizedBox(height: 16),

            // Activity (always show; dropdown assists for outward)
            if (_selectedLogType == LogType.outward)
              DropdownButtonFormField<String>(
                initialValue: _activityController.text.isEmpty
                    ? null
                    : _activityController.text,
                decoration: const InputDecoration(
                  labelText: 'Activity (choose or type)',
                  border: OutlineInputBorder(),
                ),
                items: MaterialActivities.commonActivities
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _activityController.text = v);
                  }
                },
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _activityController,
              decoration: const InputDecoration(
                labelText: 'Activity / Description',
                hintText: 'e.g., Material Received or Site Pouring',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedLogType == LogType.inward) ...[
              // Payment type
              DropdownButtonFormField<String>(
                initialValue: _paymentType,
                decoration: const InputDecoration(
                  labelText: 'Payment Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'upi', child: Text('Online/UPI')),
                  DropdownMenuItem(
                    value: 'bank_transfer',
                    child: Text('Bank Transfer'),
                  ),
                  DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                ],
                onChanged: (v) => setState(() => _paymentType = v),
              ),
              const SizedBox(height: 16),

              // Bill amount
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Bill Amount',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 24),

            // Submit Button
            FilledButton(
              onPressed: _isSubmitting ? null : _submitLog,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLog() async {
    if (_selectedItem == null) return;
    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    // Prevent over-consumption across projects
    if (_selectedLogType == LogType.outward) {
      final available = _selectedItem?.quantity ?? 0;
      if (quantity > available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quantity exceeds available stock (${available.toStringAsFixed(2)} ${_selectedItem?.unit ?? ''}).',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(inventoryRepositoryProvider);
      final log = MaterialLogModel(
        id: '',
        projectId: widget.projectId,
        itemId: _selectedItem!.id,
        logType: _selectedLogType,
        quantity: quantity,
        activity: _activityController.text.trim().isEmpty
            ? (_selectedLogType == LogType.outward
                  ? 'Material Used'
                  : 'Material Received')
            : _activityController.text.trim(),
        notes: _notesController.text.isEmpty
            ? null
            : _notesController.text.trim(),
        supplierId: _selectedSupplier?.id,
      );

      final billAmount = _amountController.text.trim().isEmpty
          ? null
          : double.tryParse(_amountController.text.trim());
      if (_selectedLogType == LogType.inward &&
          billAmount != null &&
          _paymentType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select payment type for this bill')),
        );
        setState(() => _isSubmitting = false);
        return;
      }
      await repository.addMaterialLog(
        log,
        paymentType: _paymentType,
        billAmount: _selectedLogType == LogType.inward ? billAmount : null,
        billTitle: [
          _selectedItem?.name,
          if (_selectedItem?.description != null &&
              _selectedItem!.description!.isNotEmpty)
            _selectedItem!.description,
        ].whereType<String>().join(' - '),
      );
      widget.onAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showAddMaterialDialog() async {
    final nameController = TextEditingController();
    final gradeController = TextEditingController();
    String unit = 'units';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Material'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: gradeController,
              decoration: const InputDecoration(
                labelText: 'Grade / Type (optional)',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: unit,
              items: const [
                DropdownMenuItem(value: 'bags', child: Text('Bags')),
                DropdownMenuItem(value: 'kg', child: Text('Kg')),
                DropdownMenuItem(value: 'tons', child: Text('Tons')),
                DropdownMenuItem(
                  value: 'cubic_meter',
                  child: Text('Cubic Meter'),
                ),
                DropdownMenuItem(value: 'units', child: Text('Units')),
              ],
              onChanged: (v) => unit = v ?? unit,
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                final repo = ref.read(inventoryRepositoryProvider);
                final created = await repo.addStockItem(
                  StockItemModel(
                    id: '',
                    projectId: widget.projectId,
                    name: name,
                    description: gradeController.text.trim().isEmpty
                        ? null
                        : gradeController.text.trim(),
                    quantity: 0,
                    unit: unit,
                  ),
                );
                ref.invalidate(stockItemsProvider(widget.projectId));
                setState(() {
                  _items = [..._items, created];
                  _selectedItem = created;
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed to add material: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
