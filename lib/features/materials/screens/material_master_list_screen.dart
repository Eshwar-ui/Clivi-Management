import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/widgets/custom_text_field.dart';
import '../providers/master_data_provider.dart';
import '../data/models/material_master_model.dart';
import '../data/models/material_grade_model.dart';

final allMaterialsProvider = FutureProvider.autoDispose<List<MaterialMaster>>((
  ref,
) {
  return ref.watch(materialMasterRepositoryProvider).getAllMaterials();
});

final materialGradesProvider = FutureProvider.autoDispose
    .family<List<MaterialGrade>, String>((ref, materialId) {
      return ref
          .watch(materialMasterRepositoryProvider)
          .getGradesForMaterial(materialId);
    });

class MaterialMasterListScreen extends ConsumerWidget {
  const MaterialMasterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Material Master List')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMaterialDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ref
          .watch(allMaterialsProvider)
          .when(
            data: (materials) {
              if (materials.isEmpty) {
                return const Center(child: Text('No master materials found.'));
              }

              return ListView.builder(
                itemCount: materials.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final material = materials[index];
                  return _MaterialItemCard(material: material);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
    );
  }

  Future<void> _showAddMaterialDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Master Material'),
              content: Form(
                key: formKey,
                child: CustomTextField(
                  controller: nameController,
                  label: 'Material Name (e.g. Steel, Cement)',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => saving = true);
                          try {
                            final repo = ref.read(
                              materialMasterRepositoryProvider,
                            );
                            await repo.addMaterialMaster(
                              nameController.text.trim(),
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ref.invalidate(allMaterialsProvider);
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('Error adding material: $e'),
                                ),
                              );
                            }
                          } finally {
                            if (ctx.mounted) {
                              setState(() => saving = false);
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MaterialItemCard extends ConsumerStatefulWidget {
  final MaterialMaster material;

  const _MaterialItemCard({required this.material});

  @override
  ConsumerState<_MaterialItemCard> createState() => _MaterialItemCardState();
}

class _MaterialItemCardState extends ConsumerState<_MaterialItemCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              widget.material.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
              ),
              tooltip: 'Add Grade',
              onPressed: () => _showAddGradeDialog(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
            ).copyWith(bottom: 16.0),
            child: ref
                .watch(materialGradesProvider(widget.material.id))
                .when(
                  data: (grades) {
                    if (grades.isEmpty) {
                      return const Text(
                        'No grades defined for this material.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: grades.map((g) {
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onLongPress: () => _showGradeOptions(context, g),
                          onTap: () => _showGradeOptions(context, g),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    g.gradeName,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.more_horiz,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (err, stack) => Text(
                    'Error loading grades: $err',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _showGradeOptions(BuildContext context, MaterialGrade grade) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename Grade'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditGradeDialog(context, grade);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Grade', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Delete Grade?'),
                    content: Text('Remove "${grade.gradeName}" from ${widget.material.name}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(d, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(d, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  try {
                    await ref.read(materialMasterRepositoryProvider).deleteGrade(grade.id);
                    ref.invalidate(materialGradesProvider(widget.material.id));
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditGradeDialog(BuildContext context, MaterialGrade grade) async {
    final controller = TextEditingController(text: grade.gradeName);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rename Grade'),
          content: Form(
            key: formKey,
            child: CustomTextField(
              controller: controller,
              label: 'Grade Name',
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => saving = true);
                      try {
                        await ref.read(materialMasterRepositoryProvider).updateGrade(
                          grade.id,
                          controller.text.trim(),
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ref.invalidate(materialGradesProvider(widget.material.id));
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setState(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddGradeDialog(BuildContext context) async {
    final gradeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Grade for ${widget.material.name}'),
              content: Form(
                key: formKey,
                child: CustomTextField(
                  controller: gradeController,
                  label: 'Grade Name (e.g. 500D)',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => saving = true);
                          try {
                            final repo = ref.read(
                              materialMasterRepositoryProvider,
                            );
                            await repo.addMaterialGrade(
                              materialId: widget.material.id,
                              gradeName: gradeController.text.trim(),
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ref.invalidate(
                                materialGradesProvider(widget.material.id),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Error adding grade: $e')),
                              );
                            }
                          } finally {
                            if (ctx.mounted) {
                              setState(() => saving = false);
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
