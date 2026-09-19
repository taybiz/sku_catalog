import 'package:equatable/equatable.dart';

import '../enums/trait_scope.dart';
import 'meta.dart';

/// A trait (classification) that can be attached to entities.
///
/// Traits form a parent-child tree: e.g. Switch → Breaker.
class Trait extends Equatable {
  /// Creation metadata.
  final Meta meta;

  /// Display name (e.g. "Bracket", "Fastener", "Sensor").
  final String name;

  /// Id of the parent [Trait], or null for root-level traits.
  final String? parentTraitId;

  /// Which entity categories this trait applies to.
  final List<TraitScope> scope;

  /// Creates a [Trait].
  const Trait({
    required this.meta,
    required this.name,
    this.parentTraitId,
    this.scope = const [],
  });

  /// Serializes to the original app's snake_case JSON record.
  Map<String, dynamic> toJson() => {
    ...meta.toJson(),
    'name': name,
    'parent_trait_id': parentTraitId,
    'scope': scope.map((s) => s.name).toList(),
  };

  /// Parses a [Trait] from the original app's snake_case JSON record.
  factory Trait.fromJson(Map<String, dynamic> json) => Trait(
    meta: Meta.fromJson(json),
    name: json['name'] as String? ?? '',
    parentTraitId: json['parent_trait_id'] as String?,
    scope: _parseScope(json['scope']),
  );

  static List<TraitScope> _parseScope(Object? v) {
    if (v is! List) return TraitScope.values;
    final result = <TraitScope>[];
    for (final item in v) {
      final parsed = TraitScope.values.asNameMap()[item.toString()];
      if (parsed != null) result.add(parsed);
    }
    return result.isEmpty ? TraitScope.values : result;
  }

  @override
  List<Object?> get props => [meta, name, parentTraitId, scope];
}
