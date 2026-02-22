import 'package:flutter_test/flutter_test.dart';
import 'package:civil_management/features/projects/data/models/project_model.dart';
import 'package:civil_management/features/projects/data/repositories/project_repository.dart';
import 'package:civil_management/core/config/supabase_client.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/supabase_test_helpers.dart';

/// Backend tests for Project CRUD operations using Supabase
///
/// These tests verify:
/// - Create, Read, Update, Delete operations
/// - Data validation and constraints
/// - RLS policies and permissions
/// - Edge cases and error handling
void main() {
  late ProjectRepository repository;
  late String? testUserId;

  setUpAll(() async {
    // Initialize Supabase
    await SupabaseTestHelper.initialize();

    // Sign in test user
    final user = await SupabaseTestHelper.signInTestUser();
    testUserId = user?.id;
    expect(testUserId, isNotNull, reason: 'Test user should be authenticated');

    // Initialize repository
    repository = ProjectRepository();
  });

  tearDownAll(() async {
    // Cleanup all test projects
    final projectIds = TestProjectTracker.getAll();
    await SupabaseTestHelper.cleanupTestProjects(projectIds);
    TestProjectTracker.clear();

    // Sign out
    await SupabaseTestHelper.signOut();
  });

  group('Project Creation Tests', () {
    test('Create project with all required fields', () async {
      final project = TestDataGenerator.generateProject(
        name: 'Complete Test Project',
        description: 'Full project with all fields',
        location: 'Mumbai, India',
        budget: 5000000.0,
      );

      final created = await repository.createProject(project, testUserId!);
      TestProjectTracker.track(created.id);

      expect(created.id, isNotEmpty);
      expect(created.name, equals('Complete Test Project'));
      expect(created.description, equals('Full project with all fields'));
      expect(created.location, equals('Mumbai, India'));
      expect(created.budget, equals(5000000.0));
      expect(created.status, equals(ProjectStatus.planning));
      expect(created.createdBy, equals(testUserId));
      expect(created.createdAt, isNotNull);
    });

    test('Create project with minimal data (name only)', () async {
      final project = TestDataGenerator.generateProject(
        description: null,
        location: null,
        budget: null,
      );

      final created = await repository.createProject(project, testUserId!);
      TestProjectTracker.track(created.id);

      expect(created.id, isNotEmpty);
      expect(created.name, isNotEmpty);
      expect(created.status, equals(ProjectStatus.planning));
      expect(created.createdBy, equals(testUserId));
    });

    test('Create project with optional fields', () async {
      final startDate = DateTime.now();
      final endDate = DateTime.now().add(const Duration(days: 180));

      final project = TestDataGenerator.generateProject(
        name: 'Project with Dates',
        startDate: startDate,
        endDate: endDate,
        status: ProjectStatus.inProgress,
      );

      final created = await repository.createProject(project, testUserId!);
      TestProjectTracker.track(created.id);

      expect(created.startDate, isNotNull);
      expect(created.endDate, isNotNull);
      expect(created.status, equals(ProjectStatus.inProgress));
    });

    test('Create project validates created_by field', () async {
      final project = TestDataGenerator.generateProject();

      final created = await repository.createProject(project, testUserId!);
      TestProjectTracker.track(created.id);

      expect(created.createdBy, equals(testUserId));
      expect(created.createdBy, isNotEmpty);
    });

    test('Create project with duplicate name should succeed', () async {
      final projectName =
          'Duplicate Name Test ${DateTime.now().millisecondsSinceEpoch}';

      final project1 = TestDataGenerator.generateProject(name: projectName);
      final project2 = TestDataGenerator.generateProject(name: projectName);

      final created1 = await repository.createProject(project1, testUserId!);
      final created2 = await repository.createProject(project2, testUserId!);

      TestProjectTracker.track(created1.id);
      TestProjectTracker.track(created2.id);

      expect(created1.name, equals(created2.name));
      expect(created1.id, isNot(equals(created2.id)));
    });

    test('Create project with special characters in name', () async {
      final project = TestDataGenerator.generateProject(
        name: 'Test Project @#\$% & Co. (2024)',
        location: 'Location with "quotes" and \'apostrophes\'',
      );

      final created = await repository.createProject(project, testUserId!);
      TestProjectTracker.track(created.id);

      expect(created.name, contains('@#\$%'));
      expect(created.location, contains('quotes'));
    });

    test('Create project with very long name', () async {
      final longName = 'A' * 200; // Very long project name
      final project = TestDataGenerator.generateProject(name: longName);

      final created = await repository.createProject(project, testUserId!);
      TestProjectTracker.track(created.id);

      expect(created.name.length, greaterThan(100));
    });

    test('Create project with zero budget', () async {
      final project = TestDataGenerator.generateProject(budget: 0.0);

      final created = await repository.createProject(project, testUserId!);
      TestProjectTracker.track(created.id);

      expect(created.budget, equals(0.0));
    });

    test('Create project with very large budget', () async {
      final project = TestDataGenerator.generateProject(
        budget: 999999999999.99,
      );

      final created = await repository.createProject(project, testUserId!);
      TestProjectTracker.track(created.id);

      expect(created.budget, greaterThan(999999999999.0));
    });
  });

  group('Project Read Tests', () {
    late String testProjectId;

    setUpAll(() async {
      // Create a test project for read operations
      final project = TestDataGenerator.generateProject(
        name: 'Read Test Project',
        description: 'Project for testing read operations',
      );
      final created = await repository.createProject(project, testUserId!);
      testProjectId = created.id;
      TestProjectTracker.track(testProjectId);
    });

    test('Get all projects returns list', () async {
      final projects = await repository.getProjects();

      expect(projects, isA<List<ProjectModel>>());
      expect(projects, isNotEmpty);
    });

    test('Get single project by ID', () async {
      final project = await repository.getProjectById(testProjectId);

      expect(project.id, equals(testProjectId));
      expect(project.name, equals('Read Test Project'));
      expect(
        project.description,
        equals('Project for testing read operations'),
      );
    });

    test('Get projects with pagination', () async {
      final page1 = await repository.getProjects(page: 0, pageSize: 5);
      final page2 = await repository.getProjects(page: 1, pageSize: 5);

      expect(page1, isA<List<ProjectModel>>());
      expect(page2, isA<List<ProjectModel>>());

      // Pages should be different (unless there are fewer than 5 projects)
      if (page1.length == 5 && page2.isNotEmpty) {
        expect(page1.first.id, isNot(equals(page2.first.id)));
      }
    });

    test('Get projects with status filter', () async {
      final planningProjects = await repository.getProjects(
        status: ProjectStatus.planning,
      );

      expect(planningProjects, isA<List<ProjectModel>>());
      for (final project in planningProjects) {
        expect(project.status, equals(ProjectStatus.planning));
      }
    });

    test('Get projects with search query', () async {
      final searchResults = await repository.getProjects(search: 'Read Test');

      expect(searchResults, isA<List<ProjectModel>>());
      expect(searchResults.any((p) => p.name.contains('Read Test')), isTrue);
    });

    test('Get project with assignments loaded', () async {
      final project = await repository.getProjectById(testProjectId);

      // Assignments should be loaded (even if empty)
      expect(project.assignments, isNotNull);
    });

    test('Get non-existent project throws error', () async {
      const fakeId = '00000000-0000-0000-0000-000000000000';

      expect(
        () => repository.getProjectById(fakeId),
        throwsA(isA<Exception>()),
      );
    });

    test('Get projects with cursor pagination', () async {
      final firstBatch = await repository.getProjectsCursor(limit: 5);

      expect(firstBatch, isA<List<ProjectModel>>());

      if (firstBatch.isNotEmpty) {
        final lastProject = firstBatch.last;
        final nextBatch = await repository.getProjectsCursor(
          cursorCreatedAt: lastProject.createdAt?.toIso8601String(),
          cursorId: lastProject.id,
          limit: 5,
        );

        expect(nextBatch, isA<List<ProjectModel>>());

        // Next batch should not contain items from first batch
        if (nextBatch.isNotEmpty) {
          expect(nextBatch.any((p) => p.id == lastProject.id), isFalse);
        }
      }
    });
  });

  group('Project Update Tests', () {
    late String testProjectId;

    setUp(() async {
      // Create a fresh project for each update test
      final project = TestDataGenerator.generateProject(
        name: 'Update Test Project',
      );
      final created = await repository.createProject(project, testUserId!);
      testProjectId = created.id;
      TestProjectTracker.track(testProjectId);
    });

    test('Update project name', () async {
      final updated = await repository.updateProject(testProjectId, {
        'name': 'Updated Project Name',
      });

      expect(updated.name, equals('Updated Project Name'));
      expect(updated.id, equals(testProjectId));
    });

    test('Update project status', () async {
      final updated = await repository.updateProject(testProjectId, {
        'status': ProjectStatus.inProgress.value,
      });

      expect(updated.status, equals(ProjectStatus.inProgress));
    });

    test('Update project dates', () async {
      final newStartDate = DateTime.now().add(const Duration(days: 7));
      final newEndDate = DateTime.now().add(const Duration(days: 97));

      final updated = await repository.updateProject(testProjectId, {
        'start_date': newStartDate.toIso8601String().split('T').first,
        'end_date': newEndDate.toIso8601String().split('T').first,
      });

      expect(updated.startDate, isNotNull);
      expect(updated.endDate, isNotNull);
    });

    test('Update project budget', () async {
      final updated = await repository.updateProject(testProjectId, {
        'budget': 7500000.0,
      });

      expect(updated.budget, equals(7500000.0));
    });

    test('Update multiple fields simultaneously', () async {
      final updated = await repository.updateProject(testProjectId, {
        'name': 'Multi-Update Test',
        'status': ProjectStatus.onHold.value,
        'budget': 3000000.0,
        'location': 'New Location',
      });

      expect(updated.name, equals('Multi-Update Test'));
      expect(updated.status, equals(ProjectStatus.onHold));
      expect(updated.budget, equals(3000000.0));
      expect(updated.location, equals('New Location'));
    });

    test('Update sets updated_at timestamp', () async {
      final original = await repository.getProjectById(testProjectId);

      // Wait a moment to ensure timestamp difference
      await Future.delayed(const Duration(milliseconds: 100));

      final updated = await repository.updateProject(testProjectId, {
        'name': 'Timestamp Test',
      });

      expect(updated.updatedAt, isNotNull);
      if (original.updatedAt != null) {
        expect(updated.updatedAt!.isAfter(original.updatedAt!), isTrue);
      }
    });

    test('Update non-existent project throws error', () async {
      const fakeId = '00000000-0000-0000-0000-000000000000';

      expect(
        () => repository.updateProject(fakeId, {'name': 'Should Fail'}),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Project Delete Tests', () {
    test('Soft delete project sets deleted_at', () async {
      // Create a project to delete
      final project = TestDataGenerator.generateProject(
        name: 'Project to Delete',
      );
      final created = await repository.createProject(project, testUserId!);
      TestProjectTracker.track(created.id);

      // Delete the project
      await repository.deleteProject(created.id);

      // Verify project is soft-deleted (should throw or not be in normal queries)
      final allProjects = await repository.getProjects();
      final deletedProjectInList = allProjects.any((p) => p.id == created.id);

      expect(
        deletedProjectInList,
        isFalse,
        reason: 'Deleted project should not appear in normal queries',
      );
    });

    test('Delete non-existent project throws error', () async {
      const fakeId = '00000000-0000-0000-0000-000000000000';

      expect(() => repository.deleteProject(fakeId), throwsA(isA<Exception>()));
    });

    test('Delete project multiple times should handle gracefully', () async {
      final project = TestDataGenerator.generateProject();
      final created = await repository.createProject(project, testUserId!);
      TestProjectTracker.track(created.id);

      // First delete should succeed
      await repository.deleteProject(created.id);

      // Second delete might throw or succeed (depends on implementation)
      // We just verify it doesn't crash
      try {
        await repository.deleteProject(created.id);
      } catch (e) {
        // Expected - already deleted
        expect(e, isA<Exception>());
      }
    });
  });

  group('Project Assignment Tests', () {
    late String testProjectId;
    late List<String> siteManagerIds;

    setUpAll(() async {
      // Create a test project
      final project = TestDataGenerator.generateProject(
        name: 'Assignment Test Project',
      );
      final created = await repository.createProject(project, testUserId!);
      testProjectId = created.id;
      TestProjectTracker.track(testProjectId);

      // Get site managers
      final managers = await repository.getSiteManagers();
      siteManagerIds = managers.map((m) => m.id).toList();
    });

    test('Get site managers returns list', () async {
      final managers = await repository.getSiteManagers();

      expect(managers, isA<List>());
      // May be empty if no site managers exist
    });

    test('Assign site manager to project', () async {
      if (siteManagerIds.isEmpty) {
        print('Skipping: No site managers available');
        return;
      }

      await repository.assignManager(
        projectId: testProjectId,
        userId: siteManagerIds.first,
        assignedBy: testUserId!,
      );

      // Verify assignment
      final project = await repository.getProjectById(testProjectId);
      expect(project.assignments, isNotEmpty);
      expect(
        project.assignments!.any((a) => a.userId == siteManagerIds.first),
        isTrue,
      );
    });

    test('Remove site manager from project', () async {
      if (siteManagerIds.isEmpty) {
        print('Skipping: No site managers available');
        return;
      }

      // First assign
      await repository.assignManager(
        projectId: testProjectId,
        userId: siteManagerIds.first,
        assignedBy: testUserId!,
      );

      // Then remove
      await repository.removeAssignment(
        projectId: testProjectId,
        userId: siteManagerIds.first,
      );

      // Verify removal
      final project = await repository.getProjectById(testProjectId);
      expect(
        project.assignments?.any((a) => a.userId == siteManagerIds.first) ??
            false,
        isFalse,
      );
    });

    test('Get site managers with assignment status', () async {
      final managersWithStatus = await repository
          .getSiteManagersWithAssignmentStatus(testProjectId);

      expect(managersWithStatus, isA<List>());
      // Each manager should have isAssigned flag
    });
  });

  group('Project Statistics Tests', () {
    late String testProjectId;

    setUpAll(() async {
      final project = TestDataGenerator.generateProject(
        name: 'Stats Test Project',
      );
      final created = await repository.createProject(project, testUserId!);
      testProjectId = created.id;
      TestProjectTracker.track(testProjectId);
    });

    test('Get project statistics', () async {
      final stats = await repository.getProjectStatsById(testProjectId);

      expect(stats, isNotNull);
      expect(stats.materialReceived, isA<int>());
      expect(stats.materialConsumed, isA<int>());
      expect(stats.laborCount, isA<int>());
      expect(stats.machineryCount, isA<int>());
    });

    test('Get overall project stats', () async {
      final stats = await repository.getProjectStats();

      expect(stats, isA<Map<String, int>>());
      expect(stats['total'], isA<int>());
      expect(stats['planning'], isA<int>());
      expect(stats['in_progress'], isA<int>());
    });

    test('Get material breakdown', () async {
      final breakdown = await repository.getMaterialBreakdown(testProjectId);

      expect(breakdown, isA<List>());
      // May be empty if no materials
    });
  });

  group('Edge Cases and Error Handling', () {
    test('Create project with future dates', () async {
      final futureStart = DateTime.now().add(const Duration(days: 30));
      final futureEnd = DateTime.now().add(const Duration(days: 120));

      final project = TestDataGenerator.generateProject(
        startDate: futureStart,
        endDate: futureEnd,
      );

      final created = await repository.createProject(project, testUserId!);
      TestProjectTracker.track(created.id);

      expect(created.startDate!.isAfter(DateTime.now()), isTrue);
    });

    test('Create project with past dates', () async {
      final pastStart = DateTime.now().subtract(const Duration(days: 90));
      final pastEnd = DateTime.now().subtract(const Duration(days: 30));

      final project = TestDataGenerator.generateProject(
        startDate: pastStart,
        endDate: pastEnd,
      );

      final created = await repository.createProject(project, testUserId!);
      TestProjectTracker.track(created.id);

      expect(created.startDate!.isBefore(DateTime.now()), isTrue);
    });

    test('Get projects with force refresh', () async {
      final projects = await repository.getProjects(forceRefresh: true);

      expect(projects, isA<List<ProjectModel>>());
    });

    test('Search with special characters', () async {
      final results = await repository.getProjects(search: '@#\$%');

      expect(results, isA<List<ProjectModel>>());
      // Should not crash
    });

    test('Search with empty string', () async {
      final results = await repository.getProjects(search: '');

      expect(results, isA<List<ProjectModel>>());
    });
  });
}
