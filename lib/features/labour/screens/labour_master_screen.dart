import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/labour_provider.dart';
import '../data/models/labour_model.dart';


/// Master Labour list (project_id is null)
class LabourMasterScreen extends ConsumerWidget {
  const LabourMasterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labourAsync = ref.watch(masterLabourProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Labour Master'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(masterLabourProvider),
          ),
        ],
      ),
      body: labourAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No workers in master list'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final labour = list[i];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.border),
                ),
                title: Text(labour.name),
                subtitle: labour.phone != null ? Text(labour.phone!) : null,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete') {
                      await ref
                          .read(labourRepositoryProvider)
                          .deleteLabour(labour.id);
                      ref.invalidate(masterLabourProvider);
                    } else if (value == 'edit') {
                      _openSheet(context, ref, existing: labour);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
                onTap: () => _openSheet(context, ref, existing: labour),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openSheet(
    BuildContext context,
    WidgetRef ref, {
    LabourModel? existing,
  }) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

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
                    existing == null ? 'Add Worker' : 'Edit Worker',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      prefixIcon: Icon(Icons.engineering),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setState(() => saving = true);
                            final repo = ref.read(labourRepositoryProvider);
                            if (existing == null) {
                              await repo.addLabour(
                                LabourModel(
                                  id: '',
                                  name: nameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim().isEmpty
                                      ? null
                                      : phoneCtrl.text.trim(),
                                  skillType: null,
                                  dailyWage: null,
                                  projectId: null,
                                  status: LabourStatus.active,
                                  createdBy: null,
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                ),
                              );
                            } else {
                              await repo.updateLabour(existing.id, {
                                'name': nameCtrl.text.trim(),
                                'phone': phoneCtrl.text.trim(),
                              });
                            }
                            ref.invalidate(masterLabourProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
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
}
