// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'material_receipt_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MaterialReceiptModel _$MaterialReceiptModelFromJson(Map<String, dynamic> json) {
  return _MaterialReceiptModel.fromJson(json);
}

/// @nodoc
mixin _$MaterialReceiptModel {
  String get id => throw _privateConstructorUsedError;
  String get projectId => throw _privateConstructorUsedError;
  String get receiptNumber => throw _privateConstructorUsedError;
  DateTime get receiptDate => throw _privateConstructorUsedError;
  String? get vendorId => throw _privateConstructorUsedError;
  String? get vendorNameSnapshot => throw _privateConstructorUsedError;
  String? get invoiceNumber => throw _privateConstructorUsedError;
  DateTime? get invoiceDate => throw _privateConstructorUsedError;
  double? get invoiceAmount => throw _privateConstructorUsedError;
  int get totalItems => throw _privateConstructorUsedError;
  double get subtotal => throw _privateConstructorUsedError;
  double get totalGst => throw _privateConstructorUsedError;
  double get grandTotal => throw _privateConstructorUsedError;
  String? get attachmentUrl => throw _privateConstructorUsedError;
  String? get attachmentType => throw _privateConstructorUsedError;
  String get paymentStatus => throw _privateConstructorUsedError;
  String? get paymentNotes => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  String? get confirmedBy => throw _privateConstructorUsedError;
  DateTime? get confirmedAt => throw _privateConstructorUsedError;
  List<MaterialReceiptItemModel> get items =>
      throw _privateConstructorUsedError;

  /// Serializes this MaterialReceiptModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MaterialReceiptModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MaterialReceiptModelCopyWith<MaterialReceiptModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaterialReceiptModelCopyWith<$Res> {
  factory $MaterialReceiptModelCopyWith(
    MaterialReceiptModel value,
    $Res Function(MaterialReceiptModel) then,
  ) = _$MaterialReceiptModelCopyWithImpl<$Res, MaterialReceiptModel>;
  @useResult
  $Res call({
    String id,
    String projectId,
    String receiptNumber,
    DateTime receiptDate,
    String? vendorId,
    String? vendorNameSnapshot,
    String? invoiceNumber,
    DateTime? invoiceDate,
    double? invoiceAmount,
    int totalItems,
    double subtotal,
    double totalGst,
    double grandTotal,
    String? attachmentUrl,
    String? attachmentType,
    String paymentStatus,
    String? paymentNotes,
    String status,
    String? notes,
    String createdBy,
    DateTime createdAt,
    DateTime? updatedAt,
    String? confirmedBy,
    DateTime? confirmedAt,
    List<MaterialReceiptItemModel> items,
  });
}

/// @nodoc
class _$MaterialReceiptModelCopyWithImpl<
  $Res,
  $Val extends MaterialReceiptModel
>
    implements $MaterialReceiptModelCopyWith<$Res> {
  _$MaterialReceiptModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MaterialReceiptModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? receiptNumber = null,
    Object? receiptDate = null,
    Object? vendorId = freezed,
    Object? vendorNameSnapshot = freezed,
    Object? invoiceNumber = freezed,
    Object? invoiceDate = freezed,
    Object? invoiceAmount = freezed,
    Object? totalItems = null,
    Object? subtotal = null,
    Object? totalGst = null,
    Object? grandTotal = null,
    Object? attachmentUrl = freezed,
    Object? attachmentType = freezed,
    Object? paymentStatus = null,
    Object? paymentNotes = freezed,
    Object? status = null,
    Object? notes = freezed,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? confirmedBy = freezed,
    Object? confirmedAt = freezed,
    Object? items = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            projectId: null == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                      as String,
            receiptNumber: null == receiptNumber
                ? _value.receiptNumber
                : receiptNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            receiptDate: null == receiptDate
                ? _value.receiptDate
                : receiptDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            vendorId: freezed == vendorId
                ? _value.vendorId
                : vendorId // ignore: cast_nullable_to_non_nullable
                      as String?,
            vendorNameSnapshot: freezed == vendorNameSnapshot
                ? _value.vendorNameSnapshot
                : vendorNameSnapshot // ignore: cast_nullable_to_non_nullable
                      as String?,
            invoiceNumber: freezed == invoiceNumber
                ? _value.invoiceNumber
                : invoiceNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            invoiceDate: freezed == invoiceDate
                ? _value.invoiceDate
                : invoiceDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            invoiceAmount: freezed == invoiceAmount
                ? _value.invoiceAmount
                : invoiceAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
            totalItems: null == totalItems
                ? _value.totalItems
                : totalItems // ignore: cast_nullable_to_non_nullable
                      as int,
            subtotal: null == subtotal
                ? _value.subtotal
                : subtotal // ignore: cast_nullable_to_non_nullable
                      as double,
            totalGst: null == totalGst
                ? _value.totalGst
                : totalGst // ignore: cast_nullable_to_non_nullable
                      as double,
            grandTotal: null == grandTotal
                ? _value.grandTotal
                : grandTotal // ignore: cast_nullable_to_non_nullable
                      as double,
            attachmentUrl: freezed == attachmentUrl
                ? _value.attachmentUrl
                : attachmentUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            attachmentType: freezed == attachmentType
                ? _value.attachmentType
                : attachmentType // ignore: cast_nullable_to_non_nullable
                      as String?,
            paymentStatus: null == paymentStatus
                ? _value.paymentStatus
                : paymentStatus // ignore: cast_nullable_to_non_nullable
                      as String,
            paymentNotes: freezed == paymentNotes
                ? _value.paymentNotes
                : paymentNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            confirmedBy: freezed == confirmedBy
                ? _value.confirmedBy
                : confirmedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            confirmedAt: freezed == confirmedAt
                ? _value.confirmedAt
                : confirmedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<MaterialReceiptItemModel>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MaterialReceiptModelImplCopyWith<$Res>
    implements $MaterialReceiptModelCopyWith<$Res> {
  factory _$$MaterialReceiptModelImplCopyWith(
    _$MaterialReceiptModelImpl value,
    $Res Function(_$MaterialReceiptModelImpl) then,
  ) = __$$MaterialReceiptModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String projectId,
    String receiptNumber,
    DateTime receiptDate,
    String? vendorId,
    String? vendorNameSnapshot,
    String? invoiceNumber,
    DateTime? invoiceDate,
    double? invoiceAmount,
    int totalItems,
    double subtotal,
    double totalGst,
    double grandTotal,
    String? attachmentUrl,
    String? attachmentType,
    String paymentStatus,
    String? paymentNotes,
    String status,
    String? notes,
    String createdBy,
    DateTime createdAt,
    DateTime? updatedAt,
    String? confirmedBy,
    DateTime? confirmedAt,
    List<MaterialReceiptItemModel> items,
  });
}

/// @nodoc
class __$$MaterialReceiptModelImplCopyWithImpl<$Res>
    extends _$MaterialReceiptModelCopyWithImpl<$Res, _$MaterialReceiptModelImpl>
    implements _$$MaterialReceiptModelImplCopyWith<$Res> {
  __$$MaterialReceiptModelImplCopyWithImpl(
    _$MaterialReceiptModelImpl _value,
    $Res Function(_$MaterialReceiptModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MaterialReceiptModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? receiptNumber = null,
    Object? receiptDate = null,
    Object? vendorId = freezed,
    Object? vendorNameSnapshot = freezed,
    Object? invoiceNumber = freezed,
    Object? invoiceDate = freezed,
    Object? invoiceAmount = freezed,
    Object? totalItems = null,
    Object? subtotal = null,
    Object? totalGst = null,
    Object? grandTotal = null,
    Object? attachmentUrl = freezed,
    Object? attachmentType = freezed,
    Object? paymentStatus = null,
    Object? paymentNotes = freezed,
    Object? status = null,
    Object? notes = freezed,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? confirmedBy = freezed,
    Object? confirmedAt = freezed,
    Object? items = null,
  }) {
    return _then(
      _$MaterialReceiptModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        projectId: null == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String,
        receiptNumber: null == receiptNumber
            ? _value.receiptNumber
            : receiptNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        receiptDate: null == receiptDate
            ? _value.receiptDate
            : receiptDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        vendorId: freezed == vendorId
            ? _value.vendorId
            : vendorId // ignore: cast_nullable_to_non_nullable
                  as String?,
        vendorNameSnapshot: freezed == vendorNameSnapshot
            ? _value.vendorNameSnapshot
            : vendorNameSnapshot // ignore: cast_nullable_to_non_nullable
                  as String?,
        invoiceNumber: freezed == invoiceNumber
            ? _value.invoiceNumber
            : invoiceNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        invoiceDate: freezed == invoiceDate
            ? _value.invoiceDate
            : invoiceDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        invoiceAmount: freezed == invoiceAmount
            ? _value.invoiceAmount
            : invoiceAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
        totalItems: null == totalItems
            ? _value.totalItems
            : totalItems // ignore: cast_nullable_to_non_nullable
                  as int,
        subtotal: null == subtotal
            ? _value.subtotal
            : subtotal // ignore: cast_nullable_to_non_nullable
                  as double,
        totalGst: null == totalGst
            ? _value.totalGst
            : totalGst // ignore: cast_nullable_to_non_nullable
                  as double,
        grandTotal: null == grandTotal
            ? _value.grandTotal
            : grandTotal // ignore: cast_nullable_to_non_nullable
                  as double,
        attachmentUrl: freezed == attachmentUrl
            ? _value.attachmentUrl
            : attachmentUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        attachmentType: freezed == attachmentType
            ? _value.attachmentType
            : attachmentType // ignore: cast_nullable_to_non_nullable
                  as String?,
        paymentStatus: null == paymentStatus
            ? _value.paymentStatus
            : paymentStatus // ignore: cast_nullable_to_non_nullable
                  as String,
        paymentNotes: freezed == paymentNotes
            ? _value.paymentNotes
            : paymentNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        confirmedBy: freezed == confirmedBy
            ? _value.confirmedBy
            : confirmedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        confirmedAt: freezed == confirmedAt
            ? _value.confirmedAt
            : confirmedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<MaterialReceiptItemModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MaterialReceiptModelImpl implements _MaterialReceiptModel {
  const _$MaterialReceiptModelImpl({
    required this.id,
    required this.projectId,
    required this.receiptNumber,
    required this.receiptDate,
    this.vendorId,
    this.vendorNameSnapshot,
    this.invoiceNumber,
    this.invoiceDate,
    this.invoiceAmount,
    this.totalItems = 0,
    this.subtotal = 0,
    this.totalGst = 0,
    this.grandTotal = 0,
    this.attachmentUrl,
    this.attachmentType,
    this.paymentStatus = 'pending',
    this.paymentNotes,
    this.status = 'draft',
    this.notes,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.confirmedBy,
    this.confirmedAt,
    final List<MaterialReceiptItemModel> items = const [],
  }) : _items = items;

  factory _$MaterialReceiptModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaterialReceiptModelImplFromJson(json);

  @override
  final String id;
  @override
  final String projectId;
  @override
  final String receiptNumber;
  @override
  final DateTime receiptDate;
  @override
  final String? vendorId;
  @override
  final String? vendorNameSnapshot;
  @override
  final String? invoiceNumber;
  @override
  final DateTime? invoiceDate;
  @override
  final double? invoiceAmount;
  @override
  @JsonKey()
  final int totalItems;
  @override
  @JsonKey()
  final double subtotal;
  @override
  @JsonKey()
  final double totalGst;
  @override
  @JsonKey()
  final double grandTotal;
  @override
  final String? attachmentUrl;
  @override
  final String? attachmentType;
  @override
  @JsonKey()
  final String paymentStatus;
  @override
  final String? paymentNotes;
  @override
  @JsonKey()
  final String status;
  @override
  final String? notes;
  @override
  final String createdBy;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final String? confirmedBy;
  @override
  final DateTime? confirmedAt;
  final List<MaterialReceiptItemModel> _items;
  @override
  @JsonKey()
  List<MaterialReceiptItemModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'MaterialReceiptModel(id: $id, projectId: $projectId, receiptNumber: $receiptNumber, receiptDate: $receiptDate, vendorId: $vendorId, vendorNameSnapshot: $vendorNameSnapshot, invoiceNumber: $invoiceNumber, invoiceDate: $invoiceDate, invoiceAmount: $invoiceAmount, totalItems: $totalItems, subtotal: $subtotal, totalGst: $totalGst, grandTotal: $grandTotal, attachmentUrl: $attachmentUrl, attachmentType: $attachmentType, paymentStatus: $paymentStatus, paymentNotes: $paymentNotes, status: $status, notes: $notes, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt, confirmedBy: $confirmedBy, confirmedAt: $confirmedAt, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaterialReceiptModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.receiptNumber, receiptNumber) ||
                other.receiptNumber == receiptNumber) &&
            (identical(other.receiptDate, receiptDate) ||
                other.receiptDate == receiptDate) &&
            (identical(other.vendorId, vendorId) ||
                other.vendorId == vendorId) &&
            (identical(other.vendorNameSnapshot, vendorNameSnapshot) ||
                other.vendorNameSnapshot == vendorNameSnapshot) &&
            (identical(other.invoiceNumber, invoiceNumber) ||
                other.invoiceNumber == invoiceNumber) &&
            (identical(other.invoiceDate, invoiceDate) ||
                other.invoiceDate == invoiceDate) &&
            (identical(other.invoiceAmount, invoiceAmount) ||
                other.invoiceAmount == invoiceAmount) &&
            (identical(other.totalItems, totalItems) ||
                other.totalItems == totalItems) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.totalGst, totalGst) ||
                other.totalGst == totalGst) &&
            (identical(other.grandTotal, grandTotal) ||
                other.grandTotal == grandTotal) &&
            (identical(other.attachmentUrl, attachmentUrl) ||
                other.attachmentUrl == attachmentUrl) &&
            (identical(other.attachmentType, attachmentType) ||
                other.attachmentType == attachmentType) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.paymentNotes, paymentNotes) ||
                other.paymentNotes == paymentNotes) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.confirmedBy, confirmedBy) ||
                other.confirmedBy == confirmedBy) &&
            (identical(other.confirmedAt, confirmedAt) ||
                other.confirmedAt == confirmedAt) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    projectId,
    receiptNumber,
    receiptDate,
    vendorId,
    vendorNameSnapshot,
    invoiceNumber,
    invoiceDate,
    invoiceAmount,
    totalItems,
    subtotal,
    totalGst,
    grandTotal,
    attachmentUrl,
    attachmentType,
    paymentStatus,
    paymentNotes,
    status,
    notes,
    createdBy,
    createdAt,
    updatedAt,
    confirmedBy,
    confirmedAt,
    const DeepCollectionEquality().hash(_items),
  ]);

  /// Create a copy of MaterialReceiptModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MaterialReceiptModelImplCopyWith<_$MaterialReceiptModelImpl>
  get copyWith =>
      __$$MaterialReceiptModelImplCopyWithImpl<_$MaterialReceiptModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MaterialReceiptModelImplToJson(this);
  }
}

abstract class _MaterialReceiptModel implements MaterialReceiptModel {
  const factory _MaterialReceiptModel({
    required final String id,
    required final String projectId,
    required final String receiptNumber,
    required final DateTime receiptDate,
    final String? vendorId,
    final String? vendorNameSnapshot,
    final String? invoiceNumber,
    final DateTime? invoiceDate,
    final double? invoiceAmount,
    final int totalItems,
    final double subtotal,
    final double totalGst,
    final double grandTotal,
    final String? attachmentUrl,
    final String? attachmentType,
    final String paymentStatus,
    final String? paymentNotes,
    final String status,
    final String? notes,
    required final String createdBy,
    required final DateTime createdAt,
    final DateTime? updatedAt,
    final String? confirmedBy,
    final DateTime? confirmedAt,
    final List<MaterialReceiptItemModel> items,
  }) = _$MaterialReceiptModelImpl;

  factory _MaterialReceiptModel.fromJson(Map<String, dynamic> json) =
      _$MaterialReceiptModelImpl.fromJson;

  @override
  String get id;
  @override
  String get projectId;
  @override
  String get receiptNumber;
  @override
  DateTime get receiptDate;
  @override
  String? get vendorId;
  @override
  String? get vendorNameSnapshot;
  @override
  String? get invoiceNumber;
  @override
  DateTime? get invoiceDate;
  @override
  double? get invoiceAmount;
  @override
  int get totalItems;
  @override
  double get subtotal;
  @override
  double get totalGst;
  @override
  double get grandTotal;
  @override
  String? get attachmentUrl;
  @override
  String? get attachmentType;
  @override
  String get paymentStatus;
  @override
  String? get paymentNotes;
  @override
  String get status;
  @override
  String? get notes;
  @override
  String get createdBy;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  String? get confirmedBy;
  @override
  DateTime? get confirmedAt;
  @override
  List<MaterialReceiptItemModel> get items;

  /// Create a copy of MaterialReceiptModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MaterialReceiptModelImplCopyWith<_$MaterialReceiptModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

MaterialReceiptItemModel _$MaterialReceiptItemModelFromJson(
  Map<String, dynamic> json,
) {
  return _MaterialReceiptItemModel.fromJson(json);
}

/// @nodoc
mixin _$MaterialReceiptItemModel {
  String? get id => throw _privateConstructorUsedError;
  String? get receiptId => throw _privateConstructorUsedError;
  String? get projectId => throw _privateConstructorUsedError;
  String? get materialId => throw _privateConstructorUsedError;
  String get materialName => throw _privateConstructorUsedError;
  String? get materialCategory => throw _privateConstructorUsedError;
  String? get brandCompany => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError;
  double get rate => throw _privateConstructorUsedError;
  double? get amount => throw _privateConstructorUsedError;
  double get gstPercent => throw _privateConstructorUsedError;
  double? get gstAmount => throw _privateConstructorUsedError;
  double? get totalAmount => throw _privateConstructorUsedError;
  String? get itemNotes => throw _privateConstructorUsedError;

  /// Serializes this MaterialReceiptItemModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MaterialReceiptItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MaterialReceiptItemModelCopyWith<MaterialReceiptItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaterialReceiptItemModelCopyWith<$Res> {
  factory $MaterialReceiptItemModelCopyWith(
    MaterialReceiptItemModel value,
    $Res Function(MaterialReceiptItemModel) then,
  ) = _$MaterialReceiptItemModelCopyWithImpl<$Res, MaterialReceiptItemModel>;
  @useResult
  $Res call({
    String? id,
    String? receiptId,
    String? projectId,
    String? materialId,
    String materialName,
    String? materialCategory,
    String? brandCompany,
    double quantity,
    String unit,
    double rate,
    double? amount,
    double gstPercent,
    double? gstAmount,
    double? totalAmount,
    String? itemNotes,
  });
}

/// @nodoc
class _$MaterialReceiptItemModelCopyWithImpl<
  $Res,
  $Val extends MaterialReceiptItemModel
>
    implements $MaterialReceiptItemModelCopyWith<$Res> {
  _$MaterialReceiptItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MaterialReceiptItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? receiptId = freezed,
    Object? projectId = freezed,
    Object? materialId = freezed,
    Object? materialName = null,
    Object? materialCategory = freezed,
    Object? brandCompany = freezed,
    Object? quantity = null,
    Object? unit = null,
    Object? rate = null,
    Object? amount = freezed,
    Object? gstPercent = null,
    Object? gstAmount = freezed,
    Object? totalAmount = freezed,
    Object? itemNotes = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            receiptId: freezed == receiptId
                ? _value.receiptId
                : receiptId // ignore: cast_nullable_to_non_nullable
                      as String?,
            projectId: freezed == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                      as String?,
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
            brandCompany: freezed == brandCompany
                ? _value.brandCompany
                : brandCompany // ignore: cast_nullable_to_non_nullable
                      as String?,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as double,
            unit: null == unit
                ? _value.unit
                : unit // ignore: cast_nullable_to_non_nullable
                      as String,
            rate: null == rate
                ? _value.rate
                : rate // ignore: cast_nullable_to_non_nullable
                      as double,
            amount: freezed == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double?,
            gstPercent: null == gstPercent
                ? _value.gstPercent
                : gstPercent // ignore: cast_nullable_to_non_nullable
                      as double,
            gstAmount: freezed == gstAmount
                ? _value.gstAmount
                : gstAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
            totalAmount: freezed == totalAmount
                ? _value.totalAmount
                : totalAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
            itemNotes: freezed == itemNotes
                ? _value.itemNotes
                : itemNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MaterialReceiptItemModelImplCopyWith<$Res>
    implements $MaterialReceiptItemModelCopyWith<$Res> {
  factory _$$MaterialReceiptItemModelImplCopyWith(
    _$MaterialReceiptItemModelImpl value,
    $Res Function(_$MaterialReceiptItemModelImpl) then,
  ) = __$$MaterialReceiptItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? id,
    String? receiptId,
    String? projectId,
    String? materialId,
    String materialName,
    String? materialCategory,
    String? brandCompany,
    double quantity,
    String unit,
    double rate,
    double? amount,
    double gstPercent,
    double? gstAmount,
    double? totalAmount,
    String? itemNotes,
  });
}

/// @nodoc
class __$$MaterialReceiptItemModelImplCopyWithImpl<$Res>
    extends
        _$MaterialReceiptItemModelCopyWithImpl<
          $Res,
          _$MaterialReceiptItemModelImpl
        >
    implements _$$MaterialReceiptItemModelImplCopyWith<$Res> {
  __$$MaterialReceiptItemModelImplCopyWithImpl(
    _$MaterialReceiptItemModelImpl _value,
    $Res Function(_$MaterialReceiptItemModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MaterialReceiptItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? receiptId = freezed,
    Object? projectId = freezed,
    Object? materialId = freezed,
    Object? materialName = null,
    Object? materialCategory = freezed,
    Object? brandCompany = freezed,
    Object? quantity = null,
    Object? unit = null,
    Object? rate = null,
    Object? amount = freezed,
    Object? gstPercent = null,
    Object? gstAmount = freezed,
    Object? totalAmount = freezed,
    Object? itemNotes = freezed,
  }) {
    return _then(
      _$MaterialReceiptItemModelImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        receiptId: freezed == receiptId
            ? _value.receiptId
            : receiptId // ignore: cast_nullable_to_non_nullable
                  as String?,
        projectId: freezed == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String?,
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
        brandCompany: freezed == brandCompany
            ? _value.brandCompany
            : brandCompany // ignore: cast_nullable_to_non_nullable
                  as String?,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as double,
        unit: null == unit
            ? _value.unit
            : unit // ignore: cast_nullable_to_non_nullable
                  as String,
        rate: null == rate
            ? _value.rate
            : rate // ignore: cast_nullable_to_non_nullable
                  as double,
        amount: freezed == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double?,
        gstPercent: null == gstPercent
            ? _value.gstPercent
            : gstPercent // ignore: cast_nullable_to_non_nullable
                  as double,
        gstAmount: freezed == gstAmount
            ? _value.gstAmount
            : gstAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
        totalAmount: freezed == totalAmount
            ? _value.totalAmount
            : totalAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
        itemNotes: freezed == itemNotes
            ? _value.itemNotes
            : itemNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MaterialReceiptItemModelImpl implements _MaterialReceiptItemModel {
  const _$MaterialReceiptItemModelImpl({
    this.id,
    this.receiptId,
    this.projectId,
    this.materialId,
    required this.materialName,
    this.materialCategory,
    this.brandCompany,
    required this.quantity,
    required this.unit,
    required this.rate,
    this.amount,
    this.gstPercent = 0,
    this.gstAmount,
    this.totalAmount,
    this.itemNotes,
  });

  factory _$MaterialReceiptItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaterialReceiptItemModelImplFromJson(json);

  @override
  final String? id;
  @override
  final String? receiptId;
  @override
  final String? projectId;
  @override
  final String? materialId;
  @override
  final String materialName;
  @override
  final String? materialCategory;
  @override
  final String? brandCompany;
  @override
  final double quantity;
  @override
  final String unit;
  @override
  final double rate;
  @override
  final double? amount;
  @override
  @JsonKey()
  final double gstPercent;
  @override
  final double? gstAmount;
  @override
  final double? totalAmount;
  @override
  final String? itemNotes;

  @override
  String toString() {
    return 'MaterialReceiptItemModel(id: $id, receiptId: $receiptId, projectId: $projectId, materialId: $materialId, materialName: $materialName, materialCategory: $materialCategory, brandCompany: $brandCompany, quantity: $quantity, unit: $unit, rate: $rate, amount: $amount, gstPercent: $gstPercent, gstAmount: $gstAmount, totalAmount: $totalAmount, itemNotes: $itemNotes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaterialReceiptItemModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.receiptId, receiptId) ||
                other.receiptId == receiptId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.materialId, materialId) ||
                other.materialId == materialId) &&
            (identical(other.materialName, materialName) ||
                other.materialName == materialName) &&
            (identical(other.materialCategory, materialCategory) ||
                other.materialCategory == materialCategory) &&
            (identical(other.brandCompany, brandCompany) ||
                other.brandCompany == brandCompany) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.rate, rate) || other.rate == rate) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.gstPercent, gstPercent) ||
                other.gstPercent == gstPercent) &&
            (identical(other.gstAmount, gstAmount) ||
                other.gstAmount == gstAmount) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.itemNotes, itemNotes) ||
                other.itemNotes == itemNotes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    receiptId,
    projectId,
    materialId,
    materialName,
    materialCategory,
    brandCompany,
    quantity,
    unit,
    rate,
    amount,
    gstPercent,
    gstAmount,
    totalAmount,
    itemNotes,
  );

  /// Create a copy of MaterialReceiptItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MaterialReceiptItemModelImplCopyWith<_$MaterialReceiptItemModelImpl>
  get copyWith =>
      __$$MaterialReceiptItemModelImplCopyWithImpl<
        _$MaterialReceiptItemModelImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MaterialReceiptItemModelImplToJson(this);
  }
}

abstract class _MaterialReceiptItemModel implements MaterialReceiptItemModel {
  const factory _MaterialReceiptItemModel({
    final String? id,
    final String? receiptId,
    final String? projectId,
    final String? materialId,
    required final String materialName,
    final String? materialCategory,
    final String? brandCompany,
    required final double quantity,
    required final String unit,
    required final double rate,
    final double? amount,
    final double gstPercent,
    final double? gstAmount,
    final double? totalAmount,
    final String? itemNotes,
  }) = _$MaterialReceiptItemModelImpl;

  factory _MaterialReceiptItemModel.fromJson(Map<String, dynamic> json) =
      _$MaterialReceiptItemModelImpl.fromJson;

  @override
  String? get id;
  @override
  String? get receiptId;
  @override
  String? get projectId;
  @override
  String? get materialId;
  @override
  String get materialName;
  @override
  String? get materialCategory;
  @override
  String? get brandCompany;
  @override
  double get quantity;
  @override
  String get unit;
  @override
  double get rate;
  @override
  double? get amount;
  @override
  double get gstPercent;
  @override
  double? get gstAmount;
  @override
  double? get totalAmount;
  @override
  String? get itemNotes;

  /// Create a copy of MaterialReceiptItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MaterialReceiptItemModelImplCopyWith<_$MaterialReceiptItemModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
