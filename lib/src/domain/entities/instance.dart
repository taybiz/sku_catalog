import 'package:equatable/equatable.dart';

import '../json_coercion.dart';
import 'meta.dart';

/// A concrete installed instance — one article of a [Sku].
///
/// The SKU is the class ("a 20 A single-pole switch"); an [Instance] is the
/// individual article ("the one in rack 3, position 2"). Everything true of
/// the model lives on the SKU; everything true of *this* article lives here,
/// and this class carries its own traits and attribute values so an instance
/// can be classified and valued independently of the model it came from.
class Instance extends Equatable {
  static const Object _unset = Object();

  /// Creation metadata.
  final Meta meta;

  /// Id of the [Sku] (SKU) this instance instantiates.
  final String skuId;

  /// Id of the [Locate] this instance sits at, or null when it is not placed.
  ///
  /// An instance sits at exactly one place; a place may hold many instances.
  final String? locateId;

  /// Display name.
  final String name;

  /// SKU model number, copied from the SKU for labelling.
  final String? skuModelNumber;

  /// Optional serial number.
  final String? serialNumber;

  /// Ids of images attached to this instance.
  final List<String> imageIds;

  /// Ids of traits attached to this instance (instance-level classification).
  final List<String> traitIds;

  /// Trait attribute values keyed by attribute key, for this instance.
  final Map<String, dynamic> attributeValues;

  /// Optional icon name for the UI.
  final String? icon;

  /// Creates an [Instance].
  const Instance({
    required this.meta,
    required this.skuId,
    required this.locateId,
    required this.name,
    this.skuModelNumber,
    this.serialNumber,
    this.imageIds = const [],
    this.traitIds = const [],
    this.attributeValues = const {},
    this.icon,
  });

  /// Shorthand for `meta.id`.
  String get instanceId => meta.id;

  /// Whether this instance is placed at a locate.
  bool get isPlaced => locateId != null;

  /// Creates a copy with optional field overrides. Nullable fields use the
  /// sentinel pattern so they can be explicitly cleared
  /// (e.g. `copyWith(locateId: null)` un-places the instance).
  Instance copyWith({
    Meta? meta,
    String? skuId,
    Object? locateId = _unset,
    String? name,
    Object? skuModelNumber = _unset,
    Object? serialNumber = _unset,
    List<String>? imageIds,
    List<String>? traitIds,
    Map<String, dynamic>? attributeValues,
    Object? icon = _unset,
  }) => Instance(
    meta: meta ?? this.meta,
    skuId: skuId ?? this.skuId,
    locateId: locateId == _unset ? this.locateId : locateId as String?,
    name: name ?? this.name,
    skuModelNumber: skuModelNumber == _unset
        ? this.skuModelNumber
        : skuModelNumber as String?,
    serialNumber: serialNumber == _unset
        ? this.serialNumber
        : serialNumber as String?,
    imageIds: imageIds ?? this.imageIds,
    traitIds: traitIds ?? this.traitIds,
    attributeValues: attributeValues ?? this.attributeValues,
    icon: icon == _unset ? this.icon : icon as String?,
  );

  /// Converts to JSON with snake_case keys.
  Map<String, dynamic> toJson() => {
    ...meta.toJson(),
    'sku_id': skuId,
    'locate_id': locateId,
    'name': name,
    if (skuModelNumber != null) 'sku_model_number': skuModelNumber,
    if (serialNumber != null) 'serial_number': serialNumber,
    'image_ids': imageIds,
    'trait_ids': traitIds,
    'attribute_values': attributeValues,
    'icon': icon,
  };

  /// Creates an [Instance] from snake_case JSON.
  factory Instance.fromJson(Map<String, dynamic> json) => Instance(
    meta: Meta.fromJson(json),
    skuId: json['sku_id'] as String? ?? '',
    locateId: json['locate_id'] as String?,
    name: json['name'] as String? ?? '',
    skuModelNumber: json['sku_model_number'] as String?,
    serialNumber: json['serial_number'] as String?,
    imageIds: stringListFromWire(value: json['image_ids']),
    traitIds: stringListFromWire(value: json['trait_ids']),
    attributeValues: asStringMap(value: json['attribute_values']),
    icon: json['icon'] as String?,
  );

  @override
  List<Object?> get props => [
    meta,
    skuId,
    locateId,
    name,
    skuModelNumber,
    serialNumber,
    imageIds,
    traitIds,
    attributeValues,
    icon,
  ];
}
