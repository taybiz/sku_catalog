import 'package:equatable/equatable.dart';

import '../json_coercion.dart';
import 'meta.dart';

/// A device manufacturer / vendor.
class Manufacturer extends Equatable {
  /// Creation metadata.
  final Meta meta;

  /// Display name (e.g. "GE", "Square D").
  final String name;

  /// Optional website URL.
  final String? website;

  /// Optional short manufacturer description (AI-enriched).
  final String? description;

  /// Ids of traits attached to this manufacturer.
  final List<String> traitIds;

  /// Trait attribute values keyed by attribute key.
  final Map<String, dynamic> attributeValues;

  /// Creates a [Manufacturer].
  const Manufacturer({
    required this.meta,
    required this.name,
    this.website,
    this.description,
    this.traitIds = const [],
    this.attributeValues = const {},
  });

  /// Serializes to the original app's snake_case JSON record.
  Map<String, dynamic> toJson() => {
    ...meta.toJson(),
    'name': name,
    if (website != null) 'website': website,
    if (description != null) 'description': description,
    'trait_ids': traitIds,
    'attribute_values': attributeValues,
  };

  /// Parses a [Manufacturer] from the original app's snake_case JSON record.
  factory Manufacturer.fromJson(Map<String, dynamic> json) => Manufacturer(
    meta: Meta.fromJson(json),
    name: json['name'] as String? ?? '',
    website: json['website'] as String?,
    description: json['description'] as String?,
    traitIds: stringListFromWire(json['trait_ids']),
    attributeValues: asStringMap(json['attribute_values']),
  );

  @override
  List<Object?> get props => [
    meta,
    name,
    website,
    description,
    traitIds,
    attributeValues,
  ];
}
