import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/responsive_scaffold.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/project_model.dart';
import '../providers/project_provider.dart';
import 'widgets/assign_manager_sheet.dart';

/// Project detail screen with project summary and module navigation.
class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  void _navigateBack(UserRole? role) {
    switch (role) {
      case UserRole.superAdmin:
        context.go('/super-admin/dashboard');
      case UserRole.admin:
        context.go('/admin/dashboard');
      default:
        context.go('/site-manager/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectDetailProvider(widget.projectId));
    final authState = ref.watch(authProvider);
    final isAdmin = authState.isAtLeast(UserRole.admin);
    final userRole = authState.role;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _navigateBack(userRole);
      },
      child: ResponsiveScaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            tooltip: 'Back',
            onPressed: () => _navigateBack(userRole),
          ),
          title: Text(
            projectState.project?.name ?? 'Project Details',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
                tooltip: 'Edit project',
                onPressed: () => context.pushNamed(
                  'edit-project',
                  pathParameters: {'id': widget.projectId},
                ),
              ),
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _confirmDelete,
                tooltip: 'Delete project',
              ),
          ],
        ),
        builder: (context, r) {
          if (projectState.isLoading) {
            return const LoadingWidget();
          }
          if (projectState.error != null) {
            return AppErrorWidget(message: projectState.error!);
          }
          if (projectState.project == null) {
            return const Center(child: Text('Project not found'));
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: Padding(
                padding: r.pad.copyWith(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroSection(
                      project: projectState.project!,
                      isAdmin: isAdmin,
                      onEditManager: () => _showAssignManagerSheet(context),
                      onEditProject: () => context.pushNamed(
                        'edit-project',
                        pathParameters: {'id': widget.projectId},
                      ),
                      onUpdateStatus: () => _showStatusUpdateSheet(
                        context,
                        projectState.project!,
                      ),
                      onUpdateProgress: isAdmin
                          ? () => _showProgressUpdateDialog(
                              context,
                              projectState.project!,
                            )
                          : null,
                    ),
                    const SizedBox(height: 24),
                    _ModuleNavigation(projectId: widget.projectId),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAssignManagerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignManagerSheet(projectId: widget.projectId),
    );
  }

  void _showStatusUpdateSheet(BuildContext context, ProjectModel project) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Update Project Status',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              ...ProjectStatus.values.map((status) {
                return ListTile(
                  leading: Icon(Icons.circle, color: status.color, size: 16),
                  title: Text(status.displayName),
                  trailing: project.status == status
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    if (project.status == status) return;

                    final notifier = ref.read(
                      projectDetailProvider(widget.projectId).notifier,
                    );
                    if (context.mounted) {
                      final success = await notifier.updateProject({
                        'status': status.value,
                      });
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Status updated successfully'),
                            ),
                          );
                        } else {
                          final error =
                              ref
                                  .read(projectDetailProvider(widget.projectId))
                                  .error ??
                              'Failed to update status';
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(error)));
                        }
                      }
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showProgressUpdateDialog(
    BuildContext context,
    ProjectModel project,
  ) async {
    double sliderValue = project.progress.toDouble();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Completion %'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${sliderValue.round()}%',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Slider(
                value: sliderValue,
                min: 0,
                max: 100,
                divisions: 20,
                label: '${sliderValue.round()}%',
                onChanged: (v) => setState(() => sliderValue = v),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('0%', style: TextStyle(color: AppColors.textHint)),
                  Text('100%', style: TextStyle(color: AppColors.textHint)),
                ],
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
                Navigator.pop(ctx);
                final notifier = ref.read(
                  projectDetailProvider(widget.projectId).notifier,
                );
                final success = await notifier.updateProject({
                  'progress': sliderValue.round(),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Progress updated to ${sliderValue.round()}%'
                            : 'Failed to update progress',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text(
          'This will mark the project as deleted. You can restore it later from the backend if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final notifier = ref.read(projectDetailProvider(widget.projectId).notifier);
    final success = await notifier.deleteProject();

    if (!mounted) return;
    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Project deleted')));
        context.go('/admin/dashboard');
      }
    } else {
      final error =
          ref.read(projectDetailProvider(widget.projectId)).error ??
          'Failed to delete project';
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }
}

/// The main dashboard card showing Engineer, Status, and Material Snapshot
class _HeroSection extends StatelessWidget {
  final ProjectModel project;
  final bool isAdmin;
  final VoidCallback onEditManager;
  final VoidCallback onEditProject;
  final VoidCallback onUpdateStatus;
  final VoidCallback? onUpdateProgress;

  const _HeroSection({
    required this.project,
    required this.isAdmin,
    required this.onEditManager,
    required this.onEditProject,
    required this.onUpdateStatus,
    this.onUpdateProgress,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM yyyy');
    final assignedManagers =
        project.assignments ?? const <ProjectAssignmentModel>[];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assigned Engineer Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ASSIGNED SITE MANAGERS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              if (isAdmin)
                InkWell(
                  onTap: onEditManager,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            assignedManagers.isEmpty
                ? 'Not Assigned'
                : '${assignedManagers.length} Assigned',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          if (assignedManagers.isEmpty)
            Text(
              'No site manager assigned yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: assignedManagers
                  .map(
                    (assignment) => _AssignedManagerChip(
                      name: assignment.userName ?? 'Unknown',
                      phone: assignment.userPhone,
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 20),

          // Phase/Status & Date & Edit Project
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (isAdmin)
                InkWell(
                  onTap: onUpdateStatus,
                  borderRadius: BorderRadius.circular(6),
                  child: _StatusChip(status: project.status),
                )
              else
                _StatusChip(status: project.status),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (project.endDate != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Completion by ${dateFormat.format(project.endDate!)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  if (isAdmin) ...[
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: onEditProject,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onUpdateProgress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Completion',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${project.progress}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (onUpdateProgress != null) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.edit,
                            size: 12,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (project.progress.clamp(0, 100)) / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
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

class _StatusChip extends StatelessWidget {
  final ProjectStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1), // Fixed
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AssignedManagerChip extends StatelessWidget {
  final String name;
  final String? phone;

  const _AssignedManagerChip({required this.name, this.phone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE4FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            phone == null || phone!.isEmpty ? name : '$name • $phone',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigation Modules (Vertical List)
class _ModuleNavigation extends StatelessWidget {
  final String projectId;
  const _ModuleNavigation({required this.projectId});

  @override
  Widget build(BuildContext context) {
    final modules = [
      _ModuleNavCard(
        title: 'Blueprints',
        subtitle: 'Project documents / drawings',
        icon: Icons.description_outlined,
        color: const Color(0xFFE8F0FE),
        iconColor: const Color(0xFF1967D2),
        onTap: () => context.goNamed(
          'project-blueprints',
          pathParameters: {'id': projectId},
        ),
      ),
      _ModuleNavCard(
        title: 'Operations',
        subtitle: 'Consumption and expenses',
        icon: Icons.engineering_outlined,
        color: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1565C0),
        onTap: () => context.goNamed(
          'project-operations',
          pathParameters: {'id': projectId},
        ),
      ),
      _ModuleNavCard(
        title: 'Reports / Insights',
        subtitle: 'Bills and reports',
        icon: Icons.analytics_outlined,
        color: const Color(0xFFF3E5F5),
        iconColor: const Color(0xFF7B1FA2),
        onTap: () => context.goNamed(
          'project-reports',
          pathParameters: {'id': projectId},
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth >= 820;

        if (!useGrid) {
          return Column(
            children: [
              for (var i = 0; i < modules.length; i++) ...[
                modules[i],
                if (i != modules.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 150,
          ),
          itemBuilder: (context, index) => modules[index],
        );
      },
    );
  }
}

class _ModuleNavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ModuleNavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
