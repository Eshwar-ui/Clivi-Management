import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/responsive.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/project_model.dart';
import '../providers/project_provider.dart';

/// Project list screen - shows all projects for admin, assigned projects for site manager
class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Guard against accessing position after dispose
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(projectListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectListProvider);
    final role = ref.watch(userRoleProvider);
    final isAdmin = role == UserRole.admin || role == UserRole.superAdmin;

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(
          'Projects',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        showBackButton: false,
        actions: [
          if (isAdmin)
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.filter_list, size: 20),
                color: AppColors.textPrimary,
                padding: EdgeInsets.zero,
                onPressed: () => _showFilterSheet(context),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          if (isAdmin)
            ResponsiveContent(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search projects...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(projectListProvider.notifier).search('');
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {});
                  ref.read(projectListProvider.notifier).search(value);
                },
              ),
            ),

          // Active Filter Chip
          if (state.statusFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(state.statusFilter!.displayName),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      ref
                          .read(projectListProvider.notifier)
                          .filterByStatus(null);
                    },
                  ),
                ],
              ),
            ),

          // Content
          Expanded(child: _buildContent(state, isAdmin)),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              tooltip: 'Add Project',
              onPressed: () => context.push('/projects/create'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildContent(ProjectListState state, bool isAdmin) {
    if (state.isLoading && state.projects.isEmpty) {
      return const LoadingWidget(message: 'Loading projects...');
    }

    if (state.error != null && state.projects.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => ref.read(projectListProvider.notifier).refresh(),
      );
    }

    if (state.projects.isEmpty) {
      return EmptyStateWidget(
        message: isAdmin
            ? 'No projects found.\nCreate your first project!'
            : 'No projects assigned to you yet.',
        icon: Icons.folder_open,
        action: isAdmin
            ? ElevatedButton.icon(
                onPressed: () => context.push('/projects/create'),
                icon: const Icon(Icons.add),
                label: const Text('Create Project'),
              )
            : null,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final r = R(Size(constraints.maxWidth, constraints.maxHeight));
        final columns = r.w >= 1180
            ? 3
            : r.w >= 760
            ? 2
            : 1;

        return RefreshIndicator(
          onRefresh: () => ref.read(projectListProvider.notifier).refresh(),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: columns == 1
                  ? ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          state.projects.length + (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.projects.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final project = state.projects[index];
                        return _ProjectCard(
                          project: project,
                          onTap: () => context.push('/projects/${project.id}'),
                        );
                      },
                    )
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 220,
                      ),
                      itemCount:
                          state.projects.length + (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.projects.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final project = state.projects[index];
                        return _ProjectCard(
                          project: project,
                          onTap: () => context.push('/projects/${project.id}'),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterSheet(
        currentFilter: ref.read(projectListProvider).statusFilter,
        onFilterSelected: (status) {
          ref.read(projectListProvider.notifier).filterByStatus(status);
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Project card widget
class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type and Location Header
              Row(
                children: [
                  if (project.projectType != null) ...[
                    Text(
                      project.projectType!.value.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: project.projectType!.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    if (project.location != null) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.circle,
                        size: 4,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                  if (project.location != null)
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
              const SizedBox(height: 4),
              // Name
              Text(
                project.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),

              // Info row
              Row(
                children: [
                  // Dates
                  if (project.startDate != null) ...[
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateRange(project.startDate, project.endDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  // Assigned managers count
                  if (project.assignments != null &&
                      project.assignments!.isNotEmpty) ...[
                    const Icon(
                      Icons.people,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${project.assignments!.length} manager${project.assignments!.length > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Budget
                  if (project.budget != null)
                    Text(
                      '₹${_formatBudget(project.budget!)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),

              // Progress Bar (Financial/Completion)
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Completion',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${project.progress}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(project.progress),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: project.progress / 100,
                      backgroundColor: AppColors.border.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(project.progress),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return '';
    final startStr = '${start.day}/${start.month}/${start.year}';
    if (end == null) return startStr;
    final endStr = '${end.day}/${end.month}/${end.year}';
    return '$startStr - $endStr';
  }

  String _formatBudget(double budget) {
    if (budget >= 10000000) {
      return '${(budget / 10000000).toStringAsFixed(1)}Cr';
    } else if (budget >= 100000) {
      return '${(budget / 100000).toStringAsFixed(1)}L';
    } else if (budget >= 1000) {
      return '${(budget / 1000).toStringAsFixed(1)}K';
    }
    return budget.toStringAsFixed(0);
  }

  Color _getProgressColor(int progress) {
    if (progress < 25) return AppColors.error;
    if (progress < 50) return AppColors.warning;
    if (progress < 75) return AppColors.info;
    return AppColors.success;
  }
}

/// Status chip widget

/// Filter bottom sheet
class _FilterSheet extends StatelessWidget {
  final ProjectStatus? currentFilter;
  final Function(ProjectStatus?) onFilterSelected;

  const _FilterSheet({this.currentFilter, required this.onFilterSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Status',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // All option
          _FilterOption(
            label: 'All Projects',
            isSelected: currentFilter == null,
            onTap: () => onFilterSelected(null),
          ),

          const Divider(),

          // Status options - using status.color directly
          ...ProjectStatus.values.map(
            (status) => _FilterOption(
              label: status.displayName,
              isSelected: currentFilter == status,
              onTap: () => onFilterSelected(status),
              color: status.color,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Filter option widget
class _FilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: color != null
          ? Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            )
          : null,
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      contentPadding: EdgeInsets.zero,
    );
  }
}
