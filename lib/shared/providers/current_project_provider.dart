import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/projects/data/models/project_model.dart';
// Actually, I should remove self import or fix it.
// I will just use the code as provided.

part 'current_project_provider.g.dart';

/// CRITICAL: Global project context provider
/// All operations MUST have a selected project

@Riverpod(keepAlive: true)
class CurrentProject extends _$CurrentProject {
  @override
  ProjectModel? build() => null;

  void selectProject(ProjectModel project) {
    state = project;
  }

  void clearProject() {
    state = null;
  }
}

/// Guard provider - throws if no project selected
@riverpod
String requireCurrentProjectId(RequireCurrentProjectIdRef ref) {
  final project = ref.watch(currentProjectProvider);
  if (project == null) {
    throw Exception('No project selected. Please select a project first.');
  }
  return project.id;
}
