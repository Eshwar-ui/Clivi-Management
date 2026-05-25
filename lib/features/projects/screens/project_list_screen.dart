import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/responsive.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/project_model.dart';
import '../providers/project_provider.dart';

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
      backgroundColor: AppColors.scaffoldBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final r = R(Size(constraints.maxWidth, constraints.maxHeight));

          return SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    r.isDesktop ? 32 : 20,
                    r.isDesktop ? 28 : 16,
                    r.isDesktop ? 32 : 20,
                    0,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: r.maxContentWidth),
                      child: _buildHeader(context, state, isAdmin, r),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Content
                Expanded(child: _buildContent(state, isAdmin, r)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ProjectListState state,
    bool isAdmin,
    R r,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          children: [
            Text(
              'Projects',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.projects.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            const Spacer(),
            if (isAdmin) ...[
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => _showFilterSheet(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: state.statusFilter != null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => context.push('/projects/create'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            size: 18, color: Colors.white),
                        if (r.isDesktop) ...[
                          const SizedBox(width: 6),
                          const Text(
                            'New Project',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Search + active filter
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    hintStyle: TextStyle(
                        color: AppColors.textHint, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(projectListProvider.notifier)
                                  .search('');
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    ref.read(projectListProvider.notifier).search(value);
                  },
                ),
              ),
            ),
            if (state.statusFilter != null) ...[
              const SizedBox(width: 10),
              Chip(
                label: Text(
                  state.statusFilter!.displayName,
                  style: const TextStyle(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () => ref
                    .read(projectListProvider.notifier)
                    .filterByStatus(null),
                backgroundColor: state.statusFilter!.color
                    .withValues(alpha: 0.1),
                side: BorderSide(
                    color:
                        state.statusFilter!.color.withValues(alpha: 0.3)),
                labelStyle: TextStyle(
                  color: state.statusFilter!.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildContent(ProjectListState state, bool isAdmin, R r) {
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
                  padding: EdgeInsets.symmetric(
                    horizontal: r.isDesktop ? 32 : 20,
                    vertical: 8,
                  ),
                  itemCount:
                      state.projects.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.projects.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child:
                            Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _ProjectCard(
                      project: state.projects[index],
                      onTap: () => context
                          .push('/projects/${state.projects[index].id}'),
                    );
                  },
                )
              : GridView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: r.isDesktop ? 32 : 20,
                    vertical: 8,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 200,
                  ),
                  itemCount:
                      state.projects.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.projects.length) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    return _ProjectCard(
                      project: state.projects[index],
                      onTap: () => context
                          .push('/projects/${state.projects[index].id}'),
                    );
                  },
                ),
        ),
      ),
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

// ── Project Card ──

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = project.status.color;
    final progressColor = _getProgressColor(project.progress);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.borderDark.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: status + type badges
                Row(
                  children: [
                    _Badge(
                      label: project.status.displayName,
                      color: statusColor,
                    ),
                    if (project.projectType != null) ...[
                      const SizedBox(width: 8),
                      _Badge(
                        label: project.projectType!.value,
                        color: project.projectType!.color,
                        outlined: true,
                      ),
                    ],
                    const Spacer(),
                    if (project.budget != null)
                      Text(
                        '₹${_formatBudget(project.budget!)}',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Name
                Text(
                  project.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (project.clientName != null &&
                    project.clientName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    project.clientName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 14),

                // Meta row
                Row(
                  children: [
                    if (project.location != null) ...[
                      Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          project.location!,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textHint),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (project.startDate != null) ...[
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat('MMM d, yy').format(project.startDate!),
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textHint),
                      ),
                    ],
                    if (project.assignments != null &&
                        project.assignments!.isNotEmpty) ...[
                      const Spacer(),
                      Icon(Icons.people_outline_rounded,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Text(
                        '${project.assignments!.length}',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textHint),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Progress
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: project.progress / 100,
                          backgroundColor: AppColors.border,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(progressColor),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${project.progress}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: progressColor,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

// ── Badge ──

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: outlined
            ? Border.all(color: color.withValues(alpha: 0.4))
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Filter Sheet ──

class _FilterSheet extends StatelessWidget {
  final ProjectStatus? currentFilter;
  final Function(ProjectStatus?) onFilterSelected;

  const _FilterSheet({this.currentFilter, required this.onFilterSelected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Status',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _FilterOption(
              label: 'All Projects',
              isSelected: currentFilter == null,
              onTap: () => onFilterSelected(null),
            ),
            const Divider(),
            ...ProjectStatus.values.map(
              (status) => _FilterOption(
                label: status.displayName,
                isSelected: currentFilter == status,
                onTap: () => onFilterSelected(status),
                color: status.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
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
