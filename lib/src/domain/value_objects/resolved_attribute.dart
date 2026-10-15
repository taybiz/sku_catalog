import 'package:equatable/equatable.dart';

import '../entities/trait_attribute_definition.dart';

/// Where a resolved value came from.
///
/// Four answers, and no fifth: the article set it itself; the SKU (or an ancestor
/// SKU in one of its assemblies) set it; nobody set it and the definition's own
/// default applies; or there is no value and the entry is the schema alone.
///
/// The second answer is called `fallback` because `default` is a Dart keyword.
enum AttributeValueSource {
  /// This instance set it.
  instance,

  /// The SKU — or an ancestor SKU in an assembly — set it.
  sku,

  /// Nobody set it; the attribute definition's own default applies.
  fallback,

  /// No value anywhere: the entry is the schema definition only.
  trait,
}

/// One attribute resolved across trait inheritance and instance overrides.
class ResolvedAttribute extends Equatable {
  /// Id of the attribute definition.
  final String attributeId;

  /// Attribute name.
  final String name;

  /// Final resolved value.
  final dynamic value;

  /// Unit label (e.g., `'amps'`, `'watts'`).
  final String? unit;

  /// Where the value came from — see [AttributeValueSource].
  final AttributeValueSource source;

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
