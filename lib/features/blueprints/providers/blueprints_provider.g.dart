// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blueprints_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$blueprintRepositoryHash() =>
    r'a64f5d7fa4a5c6fc8388ae28e59601b43649623f';

/// See also [blueprintRepository].
@ProviderFor(blueprintRepository)
final blueprintRepositoryProvider =
    AutoDisposeProvider<BlueprintRepository>.internal(
      blueprintRepository,
      name: r'blueprintRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$blueprintRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BlueprintRepositoryRef = AutoDisposeProviderRef<BlueprintRepository>;
String _$blueprintFoldersHash() => r'ac1a094d283ae2be747e68f4cf538d181c485221';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [blueprintFolders].
@ProviderFor(blueprintFolders)
const blueprintFoldersProvider = BlueprintFoldersFamily();

/// See also [blueprintFolders].
class BlueprintFoldersFamily extends Family<AsyncValue<List<BlueprintFolder>>> {
  /// See also [blueprintFolders].
  const BlueprintFoldersFamily();

  /// See also [blueprintFolders].
  BlueprintFoldersProvider call(String projectId) {
    return BlueprintFoldersProvider(projectId);
  }

  @override
  BlueprintFoldersProvider getProviderOverride(
    covariant BlueprintFoldersProvider provider,
  ) {
    return call(provider.projectId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'blueprintFoldersProvider';
}

/// See also [blueprintFolders].
class BlueprintFoldersProvider
    extends AutoDisposeFutureProvider<List<BlueprintFolder>> {
  /// See also [blueprintFolders].
  BlueprintFoldersProvider(String projectId)
    : this._internal(
        (ref) => blueprintFolders(ref as BlueprintFoldersRef, projectId),
        from: blueprintFoldersProvider,
        name: r'blueprintFoldersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$blueprintFoldersHash,
        dependencies: BlueprintFoldersFamily._dependencies,
        allTransitiveDependencies:
            BlueprintFoldersFamily._allTransitiveDependencies,
        projectId: projectId,
      );

  BlueprintFoldersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectId,
  }) : super.internal();

  final String projectId;

  @override
  Override overrideWith(
    FutureOr<List<BlueprintFolder>> Function(BlueprintFoldersRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BlueprintFoldersProvider._internal(
        (ref) => create(ref as BlueprintFoldersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectId: projectId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<BlueprintFolder>> createElement() {
    return _BlueprintFoldersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BlueprintFoldersProvider && other.projectId == projectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BlueprintFoldersRef
    on AutoDisposeFutureProviderRef<List<BlueprintFolder>> {
  /// The parameter `projectId` of this provider.
  String get projectId;
}

class _BlueprintFoldersProviderElement
    extends AutoDisposeFutureProviderElement<List<BlueprintFolder>>
    with BlueprintFoldersRef {
  _BlueprintFoldersProviderElement(super.provider);

  @override
  String get projectId => (origin as BlueprintFoldersProvider).projectId;
}

String _$blueprintFilesHash() => r'c3c47fc89fb990211c30d1d76539354395546ffd';

/// See also [blueprintFiles].
@ProviderFor(blueprintFiles)
const blueprintFilesProvider = BlueprintFilesFamily();

/// See also [blueprintFiles].
class BlueprintFilesFamily extends Family<AsyncValue<List<Blueprint>>> {
  /// See also [blueprintFiles].
  const BlueprintFilesFamily();

  /// See also [blueprintFiles].
  BlueprintFilesProvider call({
    required String projectId,
    required String folderName,
  }) {
    return BlueprintFilesProvider(projectId: projectId, folderName: folderName);
  }

  @override
  BlueprintFilesProvider getProviderOverride(
    covariant BlueprintFilesProvider provider,
  ) {
    return call(projectId: provider.projectId, folderName: provider.folderName);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'blueprintFilesProvider';
}

/// See also [blueprintFiles].
class BlueprintFilesProvider
    extends AutoDisposeFutureProvider<List<Blueprint>> {
  /// See also [blueprintFiles].
  BlueprintFilesProvider({
    required String projectId,
    required String folderName,
  }) : this._internal(
         (ref) => blueprintFiles(
           ref as BlueprintFilesRef,
           projectId: projectId,
           folderName: folderName,
         ),
         from: blueprintFilesProvider,
         name: r'blueprintFilesProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$blueprintFilesHash,
         dependencies: BlueprintFilesFamily._dependencies,
         allTransitiveDependencies:
             BlueprintFilesFamily._allTransitiveDependencies,
         projectId: projectId,
         folderName: folderName,
       );

  BlueprintFilesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectId,
    required this.folderName,
  }) : super.internal();

  final String projectId;
  final String folderName;

  @override
  Override overrideWith(
    FutureOr<List<Blueprint>> Function(BlueprintFilesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BlueprintFilesProvider._internal(
        (ref) => create(ref as BlueprintFilesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectId: projectId,
        folderName: folderName,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Blueprint>> createElement() {
    return _BlueprintFilesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BlueprintFilesProvider &&
        other.projectId == projectId &&
        other.folderName == folderName;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectId.hashCode);
    hash = _SystemHash.combine(hash, folderName.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BlueprintFilesRef on AutoDisposeFutureProviderRef<List<Blueprint>> {
  /// The parameter `projectId` of this provider.
  String get projectId;

  /// The parameter `folderName` of this provider.
  String get folderName;
}

class _BlueprintFilesProviderElement
    extends AutoDisposeFutureProviderElement<List<Blueprint>>
    with BlueprintFilesRef {
  _BlueprintFilesProviderElement(super.provider);

  @override
  String get projectId => (origin as BlueprintFilesProvider).projectId;
  @override
  String get folderName => (origin as BlueprintFilesProvider).folderName;
}

String _$allBlueprintsHash() => r'362fe5a89ed29f97dd790af6ce94ab02f44945c7';

/// Provider to get all blueprints for a project (not grouped by folder)
///
/// Copied from [allBlueprints].
@ProviderFor(allBlueprints)
const allBlueprintsProvider = AllBlueprintsFamily();

/// Provider to get all blueprints for a project (not grouped by folder)
///
/// Copied from [allBlueprints].
class AllBlueprintsFamily extends Family<AsyncValue<List<Blueprint>>> {
  /// Provider to get all blueprints for a project (not grouped by folder)
  ///
  /// Copied from [allBlueprints].
  const AllBlueprintsFamily();

  /// Provider to get all blueprints for a project (not grouped by folder)
  ///
  /// Copied from [allBlueprints].
  AllBlueprintsProvider call(String projectId) {
    return AllBlueprintsProvider(projectId);
  }

  @override
  AllBlueprintsProvider getProviderOverride(
    covariant AllBlueprintsProvider provider,
  ) {
    return call(provider.projectId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'allBlueprintsProvider';
}

/// Provider to get all blueprints for a project (not grouped by folder)
///
/// Copied from [allBlueprints].
class AllBlueprintsProvider extends AutoDisposeFutureProvider<List<Blueprint>> {
  /// Provider to get all blueprints for a project (not grouped by folder)
  ///
  /// Copied from [allBlueprints].
  AllBlueprintsProvider(String projectId)
    : this._internal(
        (ref) => allBlueprints(ref as AllBlueprintsRef, projectId),
        from: allBlueprintsProvider,
        name: r'allBlueprintsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$allBlueprintsHash,
        dependencies: AllBlueprintsFamily._dependencies,
        allTransitiveDependencies:
            AllBlueprintsFamily._allTransitiveDependencies,
        projectId: projectId,
      );

  AllBlueprintsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectId,
  }) : super.internal();

  final String projectId;

  @override
  Override overrideWith(
    FutureOr<List<Blueprint>> Function(AllBlueprintsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AllBlueprintsProvider._internal(
        (ref) => create(ref as AllBlueprintsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectId: projectId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Blueprint>> createElement() {
    return _AllBlueprintsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AllBlueprintsProvider && other.projectId == projectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AllBlueprintsRef on AutoDisposeFutureProviderRef<List<Blueprint>> {
  /// The parameter `projectId` of this provider.
  String get projectId;
}

class _AllBlueprintsProviderElement
    extends AutoDisposeFutureProviderElement<List<Blueprint>>
    with AllBlueprintsRef {
  _AllBlueprintsProviderElement(super.provider);

  @override
  String get projectId => (origin as AllBlueprintsProvider).projectId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
