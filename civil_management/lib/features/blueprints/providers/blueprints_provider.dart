import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/blueprint_model.dart';
import '../data/repositories/blueprint_repository.dart';

part 'blueprints_provider.g.dart';

@riverpod
BlueprintRepository blueprintRepository(BlueprintRepositoryRef ref) {
  // In a real app, you might get the client from another provider
  return BlueprintRepository();
}

@riverpod
Future<List<BlueprintFolder>> blueprintFolders(
  BlueprintFoldersRef ref,
  String projectId,
) {
  final repository = ref.watch(blueprintRepositoryProvider);
  return repository.getBlueprintFolders(projectId);
}

@riverpod
Future<List<Blueprint>> blueprintFiles(
  BlueprintFilesRef ref, {
  required String projectId,
  required String folderName,
}) {
  final repository = ref.watch(blueprintRepositoryProvider);
  return repository.getBlueprintFiles(projectId, folderName);
}

/// Provider to get all blueprints for a project (not grouped by folder)
@riverpod
Future<List<Blueprint>> allBlueprints(
  AllBlueprintsRef ref,
  String projectId,
) async {
  final repository = ref.watch(blueprintRepositoryProvider);
  // Get all folders first, then flatten all files
  final folders = await repository.getBlueprintFolders(projectId);
  final List<Blueprint> allFiles = [];

  for (final folder in folders) {
    final files = await repository.getBlueprintFiles(projectId, folder.name);
    allFiles.addAll(files);
  }

  // Sort by created date (newest first)
  allFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return allFiles;
}
