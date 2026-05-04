// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$projectStockBalanceHash() =>
    r'2d012b12a36ba9fe798054117b13ea152b3ebf2d';

/// See also [projectStockBalance].
@ProviderFor(projectStockBalance)
final projectStockBalanceProvider =
    AutoDisposeFutureProvider<List<StockBalanceModel>>.internal(
      projectStockBalance,
      name: r'projectStockBalanceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$projectStockBalanceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProjectStockBalanceRef =
    AutoDisposeFutureProviderRef<List<StockBalanceModel>>;
String _$projectReceiptsHash() => r'c40c8144cbe1bf477e0faf648ee1059674814ab9';

/// See also [ProjectReceipts].
@ProviderFor(ProjectReceipts)
final projectReceiptsProvider =
    AutoDisposeAsyncNotifierProvider<
      ProjectReceipts,
      List<MaterialReceiptModel>
    >.internal(
      ProjectReceipts.new,
      name: r'projectReceiptsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$projectReceiptsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProjectReceipts =
    AutoDisposeAsyncNotifier<List<MaterialReceiptModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
