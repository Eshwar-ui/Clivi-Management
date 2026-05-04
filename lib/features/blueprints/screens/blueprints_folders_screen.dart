import 'package:civil_management/features/blueprints/widgets/folder_grid_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../projects/providers/project_provider.dart'; // Corrected path
import '../providers/blueprints_provider.dart'; // Added missing import
import 'blueprint_upload_screen.dart';

class BlueprintsFoldersScreen extends ConsumerWidget {
  final String projectId;

  const BlueprintsFoldersScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch project for name
    final projectAsync = ref.watch(projectDetailProvider(projectId));
    final projectName = projectAsync.project?.name ?? 'Unknown Project';

    final foldersAsync = ref.watch(blueprintFoldersProvider(projectId));
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Blueprints: $projectName'),
      ),
      body: foldersAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, stack) => AppErrorWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(blueprintFoldersProvider(projectId)),
        ),
        data: (folders) {
          if (folders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.folder_off_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('No blueprint folders found for this project.'),
                  if (authState.isAtLeast(UserRole.admin)) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showUploadSheet(context),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload First Blueprint'),
                    ),
                  ],
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return FolderGridTile(folder: folder, projectId: projectId);
            },
          );
        },
      ),
      floatingActionButton:
          authState.isAtLeast(UserRole.admin) &&
              (foldersAsync.valueOrNull?.isNotEmpty ?? false)
          ? FloatingActionButton(
              onPressed: () => _showUploadSheet(context),
              child: const Icon(Icons.upload_file),
            )
          : null,
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.75,
          child: BlueprintUploadScreen(projectId: projectId),
        ),
      ),
    );
  }
}
