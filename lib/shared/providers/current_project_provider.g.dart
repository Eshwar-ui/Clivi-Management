// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_project_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$requireCurrentProjectIdHash() =>
    r'583ba8ad3f59719c13b37e40b9371c94b2377489';

/// Guard provider - throws if no project selected
///
/// Copied from [requireCurrentProjectId].
@ProviderFor(requireCurrentProjectId)
final requireCurrentProjectIdProvider = AutoDisposeProvider<String>.internal(
  requireCurrentProjectId,
  name: r'requireCurrentProjectIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$requireCurrentProjectIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RequireCurrentProjectIdRef = AutoDisposeProviderRef<String>;
String _$currentProjectHash() => r'd4c8d0b528d99f45f72cbf809f9c6287c74e6f8f';

/// CRITICAL: Global project context provider
/// All operations MUST have a selected project
///
/// Copied from [CurrentProject].
@ProviderFor(CurrentProject)
final currentProjectProvider =
    NotifierProvider<CurrentProject, ProjectModel?>.internal(
      CurrentProject.new,
      name: r'currentProjectProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentProjectHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentProject = Notifier<ProjectModel?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
