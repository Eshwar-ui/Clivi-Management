import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/models/blueprint_model.dart';

class FolderGridTile extends StatelessWidget {
  final BlueprintFolder folder;
  final String projectId;

  const FolderGridTile({
    super.key,
    required this.folder,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.go('/projects/$projectId/blueprints/${folder.name}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Folder Icon
            Expanded(
              child: Container(
                color: AppColors.primary.withValues(alpha: 0.05),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.folder_open_outlined,
                        size: 60,
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                      if (folder.isAdminOnly)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Icon(
                            Icons.lock,
                            size: 16,
                            color: AppColors.warning.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Folder Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${folder.fileCount} file${folder.fileCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
