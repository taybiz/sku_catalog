import 'package:equatable/equatable.dart';

import 'meta.dart';

/// A labeled, directed relationship edge between two *articles*:
/// [sourceInstanceId] acts on [targetInstanceId] in the role named by [kind].
///
/// This is the article-level sibling of a `SkuAssociation`, and the two are
/// **axes, not alternatives**. A fact that is true of the models belongs on the
/// SKUs (an author `edited` a work): stating it on the articles would copy one
/// model fact once per article owned and let the copies disagree. A fact that is
/// true of two particular articles belongs here (this copy is `bound_with` that
/// copy; this copy was `replaced_by` that copy): it cannot be said on the models
/// at all, because the other articles of those models are not implicated. Both
/// are real edges, and neither store sees the other's rows.
///
/// The rule this edge may not break is **an edge connects peers**: both ends name
/// an article, an article is not its own peer, and there is no endpoint here that
/// names a SKU or a place — an edge that needs to point at a model points at it
/// through the article's own `skuId`.
///
/// Like its SKU-level sibling it has no quantity, no depth, no fold and no cycle
/// guard: a relationship graph may legitimately cycle.
///
/// What belongs here is the *durable structural* fact. A loan or a provenance
/// event carries a borrower, a due date and an end, so it is a transaction rather
/// than an edge and belongs to the consumer's own store — keep this table to
/// relationships that are as true tomorrow as they are today.
class InstanceAssociation extends Equatable {
  /// Creation metadata.
  final Meta meta;

  /// Id of the acting [Instance] (the subject, e.g. the copy that was
  /// replaced).
  final String sourceInstanceId;

  /// Id of the [Instance] acted upon (e.g. its replacement).
  final String targetInstanceId;

  /// The relationship role, e.g. 'bound_with' or 'replaced_by'.
  final String kind;

  /// Creates an [InstanceAssociation].
  const InstanceAssociation({
    required this.meta,
    required this.sourceInstanceId,
    required this.targetInstanceId,
    required this.kind,
  });

  /// Converts to JSON with snake_case keys.
  Map<String, dynamic> toJson() => {
    ...meta.toJson(),
    'source_instance_id': sourceInstanceId,
    'target_instance_id': targetInstanceId,
    'kind': kind,
  };

  /// Parses an [InstanceAssociation] from a snake_case JSON record.
  factory InstanceAssociation.fromJson(Map<String, dynamic> json) =>
      InstanceAssociation(
        meta: Meta.fromJson(json),
        sourceInstanceId: json['source_instance_id'] as String? ?? '',
        targetInstanceId: json['target_instance_id'] as String? ?? '',
        kind: json['kind'] as String? ?? '',
      );

  @override
  List<Object?> get props => [meta, sourceInstanceId, targetInstanceId, kind];
}
