import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../inventory/data/models/supplier_model.dart';
import '../providers/vendor_analytics_provider.dart';
import '../data/models/vendor_summary_models.dart';
import 'vendor_detail_totals_screen.dart';

class VendorsListScreen extends ConsumerWidget {
  const VendorsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(vendorOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'refresh') {
                ref.invalidate(vendorOverviewProvider);
              } else if (value == 'delete_all') {
                _confirmBulkDelete(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
              PopupMenuItem(value: 'delete_all', child: Text('Delete All')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVendorSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: overviewAsync.when(
        data: (vendors) => vendors.isEmpty
            ? const Center(child: Text('No vendor data yet'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: vendors.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final v = vendors[index];
                  return _VendorCard(
                    vendor: v,
                    onOpen: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VendorDetailTotalsScreen(
                            vendorId: v.vendorId,
                            vendorName: v.vendorName,
                          ),
                        ),
                      );
                    },
                    onEdit: () => _showVendorSheet(
                      context,
                      ref,
                      existing: SupplierModel(
                        id: v.vendorId,
                        name: v.vendorName,
                        phone: null,
                        email: null,
                        contactPerson: null,
                        address: null,
                        category: null,
                        notes: null,
                        isActive: true,
                        createdAt: null,
                      ),
                    ),
                    onDelete: () => _confirmDelete(context, ref, v.vendorId),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showVendorSheet(
    BuildContext context,
    WidgetRef ref, {
    SupplierModel? existing,
  }) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null ? 'Add Vendor' : 'Edit Vendor',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name *'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setState(() => isSaving = true);
                              try {
                                final repo = ref.read(
                                  inventoryRepositoryProvider,
                                );
                                if (existing == null) {
                                  await repo.addSupplier(
                                    SupplierModel(
                                      id: '',
                                      name: nameController.text.trim(),
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
                                      createdAt: null,
                                    ),
                                  );
                                } else {
                                  await repo.updateSupplier(existing.id, {
                                    'name': nameController.text.trim(),
                                    'phone': phoneController.text.trim(),
                                    'email': emailController.text.trim(),
                                  });
                                }
                                ref.invalidate(vendorOverviewProvider);
                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        existing == null
                                            ? 'Vendor added'
                                            : 'Vendor updated',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to save vendor: $e'),
                                    ),
                                  );
                                }
                              } finally {
                                setState(() => isSaving = false);
                              }
                            },
                      child: Text(existing == null ? 'Save' : 'Update'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmBulkDelete(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete ALL vendors'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will deactivate all vendors.'),
            const SizedBox(height: 8),
            const Text('Type DELETE to confirm.'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Confirmation text'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim() == 'DELETE'),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await ref.read(inventoryRepositoryProvider).deleteAllSuppliers();
        ref.invalidate(vendorOverviewProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All vendors deactivated')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Bulk delete failed: $e')));
        }
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String vendorId,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete vendor'),
        content: const Text('Are you sure you want to delete this vendor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(inventoryRepositoryProvider).deleteSupplier(vendorId);
        ref.invalidate(vendorOverviewProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Vendor deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }
}

class _VendorCard extends StatelessWidget {
  final VendorOverview vendor;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VendorCard({
    required this.vendor,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        title: Text(
          vendor.vendorName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Total supplied: ${vendor.totalQuantity.toStringAsFixed(2)}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'open':
                onOpen();
                break;
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'open', child: Text('View')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: onOpen,
      ),
    );
  }
}
