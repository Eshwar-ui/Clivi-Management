import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/machinery_provider.dart';
import '../data/models/machinery_model.dart';

/// Machinery master list with add/edit/delete via bottom sheets
class MachineryMasterScreen extends ConsumerWidget {
  const MachineryMasterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machineryListAsync = ref.watch(machineryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Machinery Master'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') {
                ref.invalidate(machineryListProvider);
              } else if (value == 'delete_all') {
                _confirmDeleteAll(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
              PopupMenuItem(value: 'delete_all', child: Text('Delete All')),
            ],
          ),
        ],
      ),
      body: machineryListAsync.when(
        data: (machinery) {
          if (machinery.isEmpty) {
            return const Center(child: Text('No machinery added yet.'));
          }
          return ListView.builder(
            itemCount: machinery.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = machinery[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      item.ownershipType == 'Own'
                          ? Icons.handyman
                          : Icons.car_rental,
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.type ?? 'Unknown Type'} • '
                    '${item.registrationNo ?? 'No Reg No'}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showFormSheet(context, ref, existing: item);
                          break;
                        case 'delete':
                          _confirmDelete(context, ref, item.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () => _showFormSheet(context, ref, existing: item),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFormSheet(
    BuildContext context,
    WidgetRef ref, {
    MachineryModel? existing,
  }) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final typeController = TextEditingController(text: existing?.type ?? '');
    final regController = TextEditingController(
      text: existing?.registrationNo ?? '',
    );
    String ownership = existing?.ownershipType ?? 'Rental';
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
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
                    existing == null ? 'Add Machinery' : 'Edit Machinery',
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
                    controller: typeController,
                    decoration: const InputDecoration(labelText: 'Type *'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: regController,
                    decoration: const InputDecoration(
                      labelText: 'Registration No',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: ownership,
                    decoration: const InputDecoration(labelText: 'Ownership'),
                    items: const [
                      DropdownMenuItem(value: 'Own', child: Text('Own')),
                      DropdownMenuItem(value: 'Rental', child: Text('Rental')),
                    ],
                    onChanged: (v) => setState(() => ownership = v ?? 'Rental'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setState(() => isSaving = true);
                            final repo = ref.read(machineryRepositoryProvider);
                            try {
                              if (existing == null) {
                                await repo.createMachinery(
                                  name: nameController.text.trim(),
                                  type: typeController.text.trim(),
                                  registrationNo:
                                      regController.text.trim().isEmpty
                                      ? null
                                      : regController.text.trim(),
                                  ownershipType: ownership,
                                );
                              } else {
                                await repo.updateMachinery(
                                  machineryId: existing.id,
                                  data: {
                                    'name': nameController.text.trim(),
                                    'type': typeController.text.trim(),
                                    'registration_no': regController.text
                                        .trim(),
                                    'ownership_type': ownership,
                                  },
                                );
                              }
                              ref.invalidate(machineryListProvider);
                              if (ctx.mounted) Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    existing == null
                                        ? 'Machinery added'
                                        : 'Machinery updated',
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Save failed: $e')),
                              );
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
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete machinery'),
        content: const Text(
          'Are you sure you want to delete this machinery item?',
        ),
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
      await ref.read(machineryRepositoryProvider).deleteMachinery(id);
      ref.invalidate(machineryListProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Machinery deleted')));
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all machinery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will remove every machinery record.'),
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

    if (ok == true) {
      await ref.read(machineryRepositoryProvider).deleteAllMachinery();
      ref.invalidate(machineryListProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All machinery deleted')));
    }
  }
}
