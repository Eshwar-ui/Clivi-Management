// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_balance_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

StockBalanceModel _$StockBalanceModelFromJson(Map<String, dynamic> json) {
  return _StockBalanceModel.fromJson(json);
}

/// @nodoc
mixin _$StockBalanceModel {
  String get projectId => throw _privateConstructorUsedError;
  String get projectName => throw _privateConstructorUsedError;
  String? get materialId => throw _privateConstructorUsedError;
  String get materialName => throw _privateConstructorUsedError;
  String? get materialCategory => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError;
  double get totalReceived => throw _privateConstructorUsedError;
  double get totalConsumed => throw _privateConstructorUsedError;
  double get balance => throw _privateConstructorUsedError;
  double get totalValue => throw _privateConstructorUsedError;
  double get consumedPercentage => throw _privateConstructorUsedError;

  /// Serializes this StockBalanceModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StockBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StockBalanceModelCopyWith<StockBalanceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StockBalanceModelCopyWith<$Res> {
  factory $StockBalanceModelCopyWith(
    StockBalanceModel value,
    $Res Function(StockBalanceModel) then,
  ) = _$StockBalanceModelCopyWithImpl<$Res, StockBalanceModel>;
  @useResult
  $Res call({
    String projectId,
    String projectName,
    String? materialId,
    String materialName,
    String? materialCategory,
    String unit,
    double totalReceived,
    double totalConsumed,
    double balance,
    double totalValue,
    double consumedPercentage,
  });
}

/// @nodoc
class _$StockBalanceModelCopyWithImpl<$Res, $Val extends StockBalanceModel>
    implements $StockBalanceModelCopyWith<$Res> {
  _$StockBalanceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StockBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? projectId = null,
    Object? projectName = null,
    Object? materialId = freezed,
    Object? materialName = null,
    Object? materialCategory = freezed,
    Object? unit = null,
    Object? totalReceived = null,
    Object? totalConsumed = null,
    Object? balance = null,
    Object? totalValue = null,
    Object? consumedPercentage = null,
  }) {
    return _then(
      _value.copyWith(
            projectId: null == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                      as String,
            projectName: null == projectName
                ? _value.projectName
                : projectName // ignore: cast_nullable_to_non_nullable
                      as String,
            materialId: freezed == materialId
                ? _value.materialId
                : materialId // ignore: cast_nullable_to_non_nullable
                      as String?,
            materialName: null == materialName
                ? _value.materialName
                : materialName // ignore: cast_nullable_to_non_nullable
                      as String,
            materialCategory: freezed == materialCategory
                ? _value.materialCategory
                : materialCategory // ignore: cast_nullable_to_non_nullable
                      as String?,
            unit: null == unit
                ? _value.unit
                : unit // ignore: cast_nullable_to_non_nullable
                      as String,
            totalReceived: null == totalReceived
                ? _value.totalReceived
                : totalReceived // ignore: cast_nullable_to_non_nullable
                      as double,
            totalConsumed: null == totalConsumed
                ? _value.totalConsumed
                : totalConsumed // ignore: cast_nullable_to_non_nullable
                      as double,
            balance: null == balance
                ? _value.balance
                : balance // ignore: cast_nullable_to_non_nullable
                      as double,
            totalValue: null == totalValue
                ? _value.totalValue
                : totalValue // ignore: cast_nullable_to_non_nullable
                      as double,
            consumedPercentage: null == consumedPercentage
                ? _value.consumedPercentage
                : consumedPercentage // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StockBalanceModelImplCopyWith<$Res>
    implements $StockBalanceModelCopyWith<$Res> {
  factory _$$StockBalanceModelImplCopyWith(
    _$StockBalanceModelImpl value,
    $Res Function(_$StockBalanceModelImpl) then,
  ) = __$$StockBalanceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String projectId,
    String projectName,
    String? materialId,
    String materialName,
    String? materialCategory,
    String unit,
    double totalReceived,
    double totalConsumed,
    double balance,
    double totalValue,
    double consumedPercentage,
  });
}

/// @nodoc
class __$$StockBalanceModelImplCopyWithImpl<$Res>
    extends _$StockBalanceModelCopyWithImpl<$Res, _$StockBalanceModelImpl>
    implements _$$StockBalanceModelImplCopyWith<$Res> {
  __$$StockBalanceModelImplCopyWithImpl(
    _$StockBalanceModelImpl _value,
    $Res Function(_$StockBalanceModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StockBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? projectId = null,
    Object? projectName = null,
    Object? materialId = freezed,
    Object? materialName = null,
    Object? materialCategory = freezed,
    Object? unit = null,
    Object? totalReceived = null,
    Object? totalConsumed = null,
    Object? balance = null,
    Object? totalValue = null,
    Object? consumedPercentage = null,
  }) {
    return _then(
      _$StockBalanceModelImpl(
        projectId: null == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String,
        projectName: null == projectName
            ? _value.projectName
            : projectName // ignore: cast_nullable_to_non_nullable
                  as String,
        materialId: freezed == materialId
            ? _value.materialId
            : materialId // ignore: cast_nullable_to_non_nullable
                  as String?,
        materialName: null == materialName
            ? _value.materialName
            : materialName // ignore: cast_nullable_to_non_nullable
                  as String,
        materialCategory: freezed == materialCategory
            ? _value.materialCategory
            : materialCategory // ignore: cast_nullable_to_non_nullable
                  as String?,
        unit: null == unit
            ? _value.unit
            : unit // ignore: cast_nullable_to_non_nullable
                  as String,
        totalReceived: null == totalReceived
            ? _value.totalReceived
            : totalReceived // ignore: cast_nullable_to_non_nullable
                  as double,
        totalConsumed: null == totalConsumed
            ? _value.totalConsumed
            : totalConsumed // ignore: cast_nullable_to_non_nullable
                  as double,
        balance: null == balance
            ? _value.balance
            : balance // ignore: cast_nullable_to_non_nullable
                  as double,
        totalValue: null == totalValue
            ? _value.totalValue
            : totalValue // ignore: cast_nullable_to_non_nullable
                  as double,
        consumedPercentage: null == consumedPercentage
            ? _value.consumedPercentage
            : consumedPercentage // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StockBalanceModelImpl implements _StockBalanceModel {
  const _$StockBalanceModelImpl({
    required this.projectId,
    required this.projectName,
    this.materialId,
    required this.materialName,
    this.materialCategory,
    required this.unit,
    required this.totalReceived,
    required this.totalConsumed,
    required this.balance,
    required this.totalValue,
    required this.consumedPercentage,
  });

  factory _$StockBalanceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StockBalanceModelImplFromJson(json);

  @override
  final String projectId;
  @override
  final String projectName;
  @override
  final String? materialId;
  @override
  final String materialName;
  @override
  final String? materialCategory;
  @override
  final String unit;
  @override
  final double totalReceived;
  @override
  final double totalConsumed;
  @override
  final double balance;
  @override
  final double totalValue;
  @override
  final double consumedPercentage;

  @override
  String toString() {
    return 'StockBalanceModel(projectId: $projectId, projectName: $projectName, materialId: $materialId, materialName: $materialName, materialCategory: $materialCategory, unit: $unit, totalReceived: $totalReceived, totalConsumed: $totalConsumed, balance: $balance, totalValue: $totalValue, consumedPercentage: $consumedPercentage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StockBalanceModelImpl &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.projectName, projectName) ||
                other.projectName == projectName) &&
            (identical(other.materialId, materialId) ||
                other.materialId == materialId) &&
            (identical(other.materialName, materialName) ||
                other.materialName == materialName) &&
            (identical(other.materialCategory, materialCategory) ||
                other.materialCategory == materialCategory) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.totalReceived, totalReceived) ||
                other.totalReceived == totalReceived) &&
            (identical(other.totalConsumed, totalConsumed) ||
                other.totalConsumed == totalConsumed) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.totalValue, totalValue) ||
                other.totalValue == totalValue) &&
            (identical(other.consumedPercentage, consumedPercentage) ||
                other.consumedPercentage == consumedPercentage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    projectId,
    projectName,
    materialId,
    materialName,
    materialCategory,
    unit,
    totalReceived,
    totalConsumed,
    balance,
    totalValue,
    consumedPercentage,
  );

  /// Create a copy of StockBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StockBalanceModelImplCopyWith<_$StockBalanceModelImpl> get copyWith =>
      __$$StockBalanceModelImplCopyWithImpl<_$StockBalanceModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StockBalanceModelImplToJson(this);
  }
}

abstract class _StockBalanceModel implements StockBalanceModel {
  const factory _StockBalanceModel({
    required final String projectId,
    required final String projectName,
    final String? materialId,
    required final String materialName,
    final String? materialCategory,
    required final String unit,
    required final double totalReceived,
    required final double totalConsumed,
    required final double balance,
    required final double totalValue,
    required final double consumedPercentage,
  }) = _$StockBalanceModelImpl;

  factory _StockBalanceModel.fromJson(Map<String, dynamic> json) =
      _$StockBalanceModelImpl.fromJson;

  @override
  String get projectId;
  @override
  String get projectName;
  @override
  String? get materialId;
  @override
  String get materialName;
  @override
  String? get materialCategory;
  @override
  String get unit;
  @override
  double get totalReceived;
  @override
  double get totalConsumed;
  @override
  double get balance;
  @override
  double get totalValue;
  @override
  double get consumedPercentage;

  /// Create a copy of StockBalanceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StockBalanceModelImplCopyWith<_$StockBalanceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
