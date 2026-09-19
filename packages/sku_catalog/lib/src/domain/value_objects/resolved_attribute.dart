import 'package:equatable/equatable.dart';

import '../entities/trait_attribute_definition.dart';

/// One attribute resolved across trait inheritance and device overrides.
class ResolvedAttribute extends Equatable {
  /// Id of the attribute definition.
  final String attributeId;

  /// Attribute name.
  final String name;

  /// Final resolved value.
  final dynamic value;

  /// Unit label (e.g., `'amps'`, `'watts'`).
  final String? unit;

  /// Where this value came from: `'device'`, `'device_type'`, `'trait'`, `'default'`.
  final String source;

  /// The attribute definition schema (trait metadata).
  /// Required for UI forms to render this attribute correctly.
  final TraitAttributeDefinition def;

  /// Name of the parent trait this attribute was inherited from, if any.
  final String? inheritedFrom;

  /// Creates a [ResolvedAttribute].
  const ResolvedAttribute({
    required this.attributeId,
    required this.name,
    required this.value,
    this.unit,
    required this.source,
    required this.def,
    this.inheritedFrom,
  });

  @override
  List<Object?> get props => [
    attributeId,
    name,
    value,
    unit,
    source,
    def,
    inheritedFrom,
  ];
}
