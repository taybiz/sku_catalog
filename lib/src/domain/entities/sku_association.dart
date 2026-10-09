import 'package:equatable/equatable.dart';

import 'meta.dart';

/// A labeled, directed relationship edge: [sourceSkuId] acts on [targetSkuId]
/// in the role named by [kind].
///
/// Unlike a [SkuComponent] (a BOM containment edge with a quantity, a fold,
/// and a cycle guard), an association is *associative*: it has no quantity,
/// no depth, no fold, and cycles are legitimate — an ontology of
/// `Smith --edited--> Anthology` needs no "how many of" and must not be
/// treated as a part of a build.
class SkuAssociation extends Equatable {
  /// Creation metadata.
  final Meta meta;

  /// Id of the acting [Sku] (the subject, e.g. an author).
  final String sourceSkuId;

  /// Id of the [Sku] acted upon (e.g. an anthology).
  final String targetSkuId;

  /// The relationship role, e.g. 'edited' or 'contributed_to'.
  final String kind;

  /// Creates a [SkuAssociation].
  const SkuAssociation({
    required this.meta,
    required this.sourceSkuId,
    required this.targetSkuId,
    required this.kind,
  });

  /// Converts to JSON with snake_case keys.
  Map<String, dynamic> toJson() => {
    ...meta.toJson(),
    'source_sku_id': sourceSkuId,
    'target_sku_id': targetSkuId,
    'kind': kind,
  };

  /// Parses a [SkuAssociation] from a snake_case JSON record.
  factory SkuAssociation.fromJson(Map<String, dynamic> json) => SkuAssociation(
    meta: Meta.fromJson(json),
    sourceSkuId: json['source_sku_id'] as String? ?? '',
    targetSkuId: json['target_sku_id'] as String? ?? '',
    kind: json['kind'] as String? ?? '',
  );

  @override
  List<Object?> get props => [meta, sourceSkuId, targetSkuId, kind];
}
