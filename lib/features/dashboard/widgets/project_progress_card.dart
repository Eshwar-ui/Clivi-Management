import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/models/dashboard_models.dart';

/// A compact card for displaying project progress on dashboard
class ProjectProgressCard extends StatelessWidget {
  final ProjectSummary project;
  final VoidCallback? onTap;

  const ProjectProgressCard({super.key, required this.project, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTypeBadge(context),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: project.progress / 100,
                  backgroundColor: AppColors.border.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(project.progress),
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),

              // Progress text and days remaining
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${project.progress}% complete',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (project.daysRemaining != null)
                    Text(
                      '${project.daysRemaining} days left',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: project.daysRemaining! < 7
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),

              // Location
              if (project.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        project.location!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTypeColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        project.displayType,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getTypeColor(),
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (project.projectType?.toLowerCase()) {
      case 'residential':
        return AppColors.info;
      case 'commercial':
        return AppColors.primary;
      case 'infrastructure':
        return AppColors.warning;
      case 'industrial':
        return AppColors.admin;
      default:
        return AppColors.secondary;
    }
  }

  Color _getProgressColor(int progress) {
    if (progress < 25) return AppColors.error;
    if (progress < 50) return AppColors.warning;
    if (progress < 75) return AppColors.info;
    return AppColors.success;
  }
}

/// Horizontal list of project progress cards
class ProjectProgressList extends StatelessWidget {
  final List<ProjectSummary> projects;
  final bool isLoading;
  final void Function(ProjectSummary)? onProjectTap;

  const ProjectProgressList({
    super.key,
    required this.projects,
    this.isLoading = false,
    this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (projects.isEmpty) {
      return _buildEmptyState(context);
    }

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: projects.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final project = projects[index];
          return SizedBox(
            width: 280,
            child: ProjectProgressCard(
              project: project,
              onTap: () => onProjectTap?.call(project),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: 280,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Text(
        'No active projects',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
