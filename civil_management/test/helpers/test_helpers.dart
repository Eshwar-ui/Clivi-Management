import 'package:civil_management/features/projects/data/models/project_model.dart';

/// Test constants and credentials
class TestConstants {
  // Test credentials
  static const String testEmail = 'admin@gmail.com';
  static const String testPassword = 'Admin123';

  // Test timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(seconds: 60);

  // Supabase project ID
  static const String supabaseProjectId = 'fhochkjwsmwuiiqqdupa';
}

/// Generate random test project data
class TestDataGenerator {
  static int _counter = 0;

  static ProjectModel generateProject({
    String? name,
    String? description,
    String? location,
    ProjectStatus? status,
    double? budget,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _counter++;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return ProjectModel(
      id: '', // Will be set by Supabase
      name: name ?? 'Test Project $_counter - $timestamp',
      description:
          description ?? 'Test project description for automated testing',
      location: location ?? 'Test Location $_counter',
      status: status ?? ProjectStatus.planning,
      budget: budget ?? 1000000.0,
      startDate: startDate ?? DateTime.now(),
      endDate: endDate ?? DateTime.now().add(const Duration(days: 90)),
      projectType: ProjectType.commercial,
    );
  }

  static Map<String, dynamic> generateProjectJson({
    String? name,
    String? description,
    String? location,
    ProjectStatus? status,
    double? budget,
  }) {
    _counter++;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return {
      'name': name ?? 'Test Project $_counter - $timestamp',
      'description': description ?? 'Test project description',
      'location': location ?? 'Test Location $_counter',
      'status': (status ?? ProjectStatus.planning).value,
      'budget': budget ?? 1000000.0,
      'project_type': 'Commercial',
      'start_date': DateTime.now().toIso8601String().split('T').first,
      'end_date': DateTime.now()
          .add(const Duration(days: 90))
          .toIso8601String()
          .split('T')
          .first,
      'progress': 0,
    };
  }
}

/// Track created test projects for cleanup
class TestProjectTracker {
  static final List<String> _createdProjectIds = [];

  static void track(String projectId) {
    _createdProjectIds.add(projectId);
  }

  static List<String> getAll() => List.from(_createdProjectIds);

  static void clear() {
    _createdProjectIds.clear();
  }
}
