import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../projects/providers/project_provider.dart';
import '../data/models/blueprint_model.dart';
import '../providers/blueprints_provider.dart';
import '../widgets/blueprint_breadcrumb.dart';
import '../widgets/blueprint_card.dart';
import 'blueprint_upload_screen.dart';

class BlueprintFilesScreen extends ConsumerStatefulWidget {
  final String projectId;

  const BlueprintFilesScreen({super.key, required this.projectId});

  @override
  ConsumerState<BlueprintFilesScreen> createState() =>
      _BlueprintFilesScreenState();
}

class _BlueprintFilesScreenState extends ConsumerState<BlueprintFilesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUploadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.75,
          child: BlueprintUploadScreen(projectId: widget.projectId),
        ),
      ),
    );
  }

  Future<void> _deleteBlueprint(Blueprint blueprint) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Blueprint'),
        content: Text(
          'Are you sure you want to delete "${blueprint.folderName}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(blueprintRepositoryProvider).deleteBlueprint(blueprint.id);

      // Invalidate provider to refresh the list
      ref.invalidate(allBlueprintsProvider(widget.projectId));
      ref.invalidate(blueprintFoldersProvider(widget.projectId));
      ref.invalidate(
        blueprintFilesProvider(
          projectId: widget.projectId,
          folderName: blueprint.folderName,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Blueprint deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete blueprint: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectDetailProvider(widget.projectId));
    final projectName = projectAsync.project?.name ?? 'Unknown Project';

    final filesAsync = ref.watch(allBlueprintsProvider(widget.projectId));

    final authState = ref.watch(authProvider);
    final isAdmin = authState.isAtLeast(UserRole.admin);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          projectName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          BlueprintBreadcrumb(projectName: projectName, folderName: null),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search drawings...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Files list
          Expanded(
            child: filesAsync.when(
              loading: () => const LoadingWidget(),
              error: (err, stack) => AppErrorWidget(
                message: err.toString(),
                onRetry: () =>
                    ref.invalidate(allBlueprintsProvider(widget.projectId)),
              ),
              data: (files) {
                // Filter files based on search query
                final filteredFiles = _searchQuery.isEmpty
                    ? files
                    : files.where((file) {
                        return file.fileName.toLowerCase().contains(
                              _searchQuery,
                            ) ||
                            file.folderName.toLowerCase().contains(
                              _searchQuery,
                            );
                      }).toList();

                if (filteredFiles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty
                              ? Icons.folder_off_outlined
                              : Icons.search_off,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No blueprints found.'
                              : 'No blueprints match your search.',
                        ),
                        if (_searchQuery.isEmpty && isAdmin) ...[
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _showUploadSheet,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload First Blueprint'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // Group files by admin/general
                final adminFiles = filteredFiles
                    .where((f) => f.isAdminOnly)
                    .toList();
                final generalFiles = filteredFiles
                    .where((f) => !f.isAdminOnly)
                    .toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Blueprints header with Create Folders button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Blueprints',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isAdmin)
                          TextButton(
                            onPressed: _showUploadSheet,
                            child: const Text('Create Folders'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Admin Section
                    if (adminFiles.isNotEmpty && isAdmin) ...[
                      const Row(
                        children: [
                          Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...adminFiles.map(
                        (file) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BlueprintCard(
                            blueprint: file,
                            onTap: () {
                              context.push(
                                '/projects/${widget.projectId}/blueprints/view/${file.id}',
                                extra: file,
                              );
                            },
                            onDelete: isAdmin
                                ? () => _deleteBlueprint(file)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // General Section
                    if (generalFiles.isNotEmpty) ...[
                      const Row(
                        children: [
                          Text(
                            'General',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...generalFiles.map(
                        (file) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BlueprintCard(
                            blueprint: file,
                            onTap: () {
                              context.push(
                                '/projects/${widget.projectId}/blueprints/view/${file.id}',
                                extra: file,
                              );
                            },
                            onDelete: isAdmin
                                ? () => _deleteBlueprint(file)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _showUploadSheet,
              child: const Icon(Icons.upload_file),
            )
          : null,
    );
  }
}
