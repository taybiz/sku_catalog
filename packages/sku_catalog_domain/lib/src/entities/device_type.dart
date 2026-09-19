import 'package:equatable/equatable.dart';

import '../json_coercion.dart';
import 'meta.dart';

/// A stock-keeping unit (product model) manufactured by a [Manufacturer].
class DeviceType extends Equatable {
  /// Creation metadata.
  final Meta meta;

  /// Id of the owning [Manufacturer].
  final String manufacturerId;

  /// Model number (unique per manufacturer).
  final String modelNumber;

  /// Optional manufacturer-specific model number.
  final String? manufacturerModelNumber;

  /// Ids of traits attached to this SKU.
  final List<String> traitIds;

  /// Ids of images attached to this SKU.
  final List<String> imageIds;

  /// Trait attribute values keyed by attribute key.
  final Map<String, dynamic> attributeValues;

  /// Optional icon name for the UI.
  final String? icon;

  /// Creates a [DeviceType].
  const DeviceType({
    required this.meta,
    required this.manufacturerId,
    required this.modelNumber,
    this.manufacturerModelNumber,
    this.traitIds = const [],
    this.imageIds = const [],
    this.attributeValues = const {},
    this.icon,
  });

  /// Converts to JSON with snake_case keys.
  Map<String, dynamic> toJson() => {
    ...meta.toJson(),
    'manufacturer_id': manufacturerId,
    'model_number': modelNumber,
    if (manufacturerModelNumber != null)
      'manufacturer_model_number': manufacturerModelNumber,
    'trait_ids': traitIds,
    'image_ids': imageIds,
    'attribute_values': attributeValues,
    'icon': icon,
  };

  /// Creates [DeviceType] from snake_case JSON.
  factory DeviceType.fromJson(Map<String, dynamic> json) => DeviceType(
    meta: Meta.fromJson(json),
    manufacturerId: json['manufacturer_id'] as String? ?? '',
    modelNumber: json['model_number'] as String? ?? '',
    manufacturerModelNumber: json['manufacturer_model_number'] as String?,
    traitIds: stringListFromWire(json['trait_ids']),
    imageIds: stringListFromWire(json['image_ids']),
    attributeValues: asStringMap(json['attribute_values']),
    icon: json['icon'] as String?,
  );

  /// Creates a copy with optional field overrides.
  DeviceType copyWith({
    Meta? meta,
    String? manufacturerId,
    String? modelNumber,
    Object? manufacturerModelNumber = _unset,
    List<String>? traitIds,
    List<String>? imageIds,
    Map<String, dynamic>? attributeValues,
    Object? icon = _unset,
  }) => DeviceType(
    meta: meta ?? this.meta,
    manufacturerId: manufacturerId ?? this.manufacturerId,
    modelNumber: modelNumber ?? this.modelNumber,
    manufacturerModelNumber: manufacturerModelNumber == _unset
        ? this.manufacturerModelNumber
        : manufacturerModelNumber as String?,
    traitIds: traitIds ?? this.traitIds,
    imageIds: imageIds ?? this.imageIds,
    attributeValues: attributeValues ?? this.attributeValues,
    icon: icon == _unset ? this.icon : icon as String?,
  );

  static const Object _unset = Object();

  @override
  List<Object?> get props => [
    meta,
    manufacturerId,
    modelNumber,
    manufacturerModelNumber,
    traitIds,
    imageIds,
    attributeValues,
    icon,
  ];
}
