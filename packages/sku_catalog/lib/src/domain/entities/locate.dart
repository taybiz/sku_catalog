import 'package:equatable/equatable.dart';

import '../json_coercion.dart';
import 'meta.dart';

/// A physical location (room, floor, building) forming a parent-child tree.
class Locate extends Equatable {
  /// Creation metadata.
  final Meta meta;

  /// Display name.
  final String name;

  /// Id of the parent [Locate], or null for root-level.
  final String? parentLocateId;

  /// Ids of images attached to this locate.
  final List<String> imageIds;

  /// Optional icon name for the UI.
  final String? icon;

  /// Ids of traits attached to this locate.
  final List<String> traitIds;

  /// Trait attribute values keyed by attribute key.
  final Map<String, dynamic> attributeValues;

  /// Creates a [Locate].
  const Locate({
    required this.meta,
    required this.name,
    this.parentLocateId,
    this.imageIds = const [],
    this.icon,
    this.traitIds = const [],
    this.attributeValues = const {},
  });

  /// Serializes to the original app's snake_case JSON record.
  Map<String, dynamic> toJson() => {
    ...meta.toJson(),
    'name': name,
    'parent_locate_id': parentLocateId,
    'image_ids': imageIds,
    'icon': icon,
    'trait_ids': traitIds,
    'attribute_values': attributeValues,
  };

  /// Parses a [Locate] from the original app's snake_case JSON record.
  factory Locate.fromJson(Map<String, dynamic> json) => Locate(
    meta: Meta.fromJson(json),
    name: json['name'] as String? ?? '',
    parentLocateId: json['parent_locate_id'] as String?,
    imageIds: stringListFromWire(json['image_ids']),
    icon: json['icon'] as String?,
    traitIds: stringListFromWire(json['trait_ids']),
    attributeValues: asStringMap(json['attribute_values']),
  );

  @override
  List<Object?> get props => [
    meta,
    name,
    parentLocateId,
    imageIds,
    icon,
    traitIds,
    attributeValues,
  ];
}
