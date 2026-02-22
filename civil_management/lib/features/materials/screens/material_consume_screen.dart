import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/stock_provider.dart';
import '../providers/repository_providers.dart';

// Provider imported from stock_provider.dart

class MaterialConsumeScreen extends ConsumerStatefulWidget {
  final String projectId;
  final bool isEmbedded;

  const MaterialConsumeScreen({
    super.key,
    required this.projectId,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<MaterialConsumeScreen> createState() =>
      _MaterialConsumeScreenState();
}

class _MaterialConsumeScreenState extends ConsumerState<MaterialConsumeScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedStockItemId; // Changed from Map to ID string
  Map<String, dynamic>?
  _currentStockItem; // To store the resolved item for logic
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStockItemId == null || _currentStockItem == null) return;

    final currentStock = (_currentStockItem!['current_stock'] as num)
        .toDouble();
    final consumeQty = double.parse(_quantityController.text);

    if (consumeQty > currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: Only $currentStock ${_currentStockItem!['unit']} available',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(stockRepositoryProvider)
          .logMaterialOutward(
            projectId: widget.projectId,
            itemId: _selectedStockItemId!,
            quantity: consumeQty,
            activity: _activityController.text.isNotEmpty
                ? _activityController.text
                : 'Material Consumed',
            notes: _notesController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consumption logged successfully')),
        );
        ref.invalidate(
          materialLogsProvider(widget.projectId),
        ); // Refresh logs history
        ref.invalidate(
          stockBalanceProvider(widget.projectId),
        ); // Refresh balance

        if (widget.isEmbedded) {
          Navigator.pop(context); // Close bottom sheet
        } else {
          // Reset form if not embedded
          setState(() {
            _selectedStockItemId = null;
            _currentStockItem = null;
            _quantityController.clear();
            _activityController.clear();
            _notesController.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(stockBalanceProvider(widget.projectId));

    final bodyContent = stockAsync.when(
      data: (stockItems) {
        // Filter out items with 0 stock
        final availableItems = stockItems
            .where((i) => (i['current_stock'] as num) > 0)
            .toList();

        if (availableItems.isEmpty) {
          return const Center(child: Text('No materials available to consume'));
        }

        // Resolve the selected item object from the ID
        _currentStockItem = null;
        if (_selectedStockItemId != null) {
          try {
            _currentStockItem = availableItems.firstWhere(
              (item) => item['item_id'] == _selectedStockItemId,
            );
          } catch (e) {
            // Item might have disappeared or has 0 stock now
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _currentStockItem != null
                      ? _selectedStockItemId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Select Material',
                    border: OutlineInputBorder(),
                  ),
                  items: availableItems.map((item) {
                    return DropdownMenuItem(
                      value: item['item_id'] as String,
                      child: Text(
                        '${item['name']} ${item['grade'] ?? ''} (${item['current_stock']} ${item['unit']})',
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedStockItemId = val;
                      // Reset quantity if changed
                      _quantityController.clear();
                    });
                  },
                  validator: (val) =>
                      val == null ? 'Please select a material' : null,
                ),
                const SizedBox(height: 16),

                if (_currentStockItem != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Available: ${_currentStockItem!['current_stock']} ${_currentStockItem!['unit']}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  CustomTextField(
                    controller: _quantityController,
                    label: 'Quantity Consumed',
                    hintText: '0.0',
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (double.tryParse(val) == null) return 'Invalid number';
                      if (double.parse(val) <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _activityController,
                    label: 'Activity / Purpose',
                    hintText: 'e.g. Foundation Work',
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _notesController,
                    label: 'Notes (Optional)',
                    hintText: 'Any remarks...',
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Log Consumption',
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );

    if (widget.isEmbedded) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.upload_rounded, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Consume Material',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(child: bodyContent),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Log Consumption')),
      body: bodyContent,
    );
  }
}
