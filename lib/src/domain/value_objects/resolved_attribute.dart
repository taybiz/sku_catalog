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

  /// Where the value came from:
  ///
  /// - `'device'` — this instance set it;
  /// - `'device_type'` — the SKU, or an ancestor SKU in one of its assemblies,
  ///   set it (see [inheritedFrom]);
  /// - `'default'` — nobody set it and [def]'s default applies;
  /// - `'trait'` — no value anywhere; the entry is the schema definition only.
  final String source;

  /// The attribute definition schema (trait metadata).
  /// Required for UI forms to render this attribute correctly.
  final TraitAttributeDefinition def;

  /// Model number of the ancestor SKU the value was inherited from, when the
  /// value came from an assembly. Null when the instance, the SKU itself, or
  /// [def]'s default supplied it.
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
