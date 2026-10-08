import 'package:equatable/equatable.dart';

import '../json_coercion.dart';
import 'meta.dart';

/// A stock-keeping unit (product model) manufactured by a [Manufacturer].
class Sku extends Equatable {
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

  /// Creates a [Sku].
  const Sku({
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

  /// Creates [Sku] from snake_case JSON.
  factory Sku.fromJson(Map<String, dynamic> json) => Sku(
    meta: Meta.fromJson(json),
    manufacturerId: json['manufacturer_id'] as String? ?? '',
    modelNumber: json['model_number'] as String? ?? '',
    manufacturerModelNumber: json['manufacturer_model_number'] as String?,
    traitIds: stringListFromWire(value: json['trait_ids']),
    imageIds: stringListFromWire(value: json['image_ids']),
    attributeValues: asStringMap(value: json['attribute_values']),
    icon: json['icon'] as String?,
  );

  /// Creates a copy with optional field overrides.
  Sku copyWith({
    Meta? meta,
    String? manufacturerId,
    String? modelNumber,
    Object? manufacturerModelNumber = _unset,
    List<String>? traitIds,
    List<String>? imageIds,
    Map<String, dynamic>? attributeValues,
    Object? icon = _unset,
  }) => Sku(
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
