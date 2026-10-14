import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';
import 'resolve_schema.dart';

/// Resolves the attribute schema in scope for one instance.
///
/// [ResolveSchema] answers "which attributes apply to these trait ids"; this
/// answers *which trait ids those are* for an article: the traits the instance
/// carries itself, plus the traits of the SKU it instantiates, each walked up its
/// parent chain. An instance is classified independently of its model, so the
/// two claims merge — and this merged schema is what a form for that article
/// renders, and what `AssertUniqueAttributeValues` measures its values against.
///
/// Two boundaries are deliberate:
///
/// - **A SKU nobody stored contributes nothing.** An instance pointing at a model
///   that is not there is the consumer's to surface; this is not the place to
///   start refusing to describe an article.
/// - **The SKUs above the model in an assembly are not in scope.** A value an
///   article inherits from the assembly it sits in is the assembly's claim, not
///   the article's own.
class ResolveInstanceSchema {
  /// Creates a [ResolveInstanceSchema] use case.
  const ResolveInstanceSchema({
    required ISkuRepository skuRepository,
    required ResolveSchema resolveSchema,
  }) : _skuRepository = skuRepository,
       _resolveSchema = resolveSchema;

  final ISkuRepository _skuRepository;
  final ResolveSchema _resolveSchema;

  /// Executes the use case: the schema for [instance], definitions only.
  ///
  /// `ResolvedAttribute.source` is `'trait'` and `value` is null for every entry,
  /// exactly as [ResolveSchema] reports a schema on its own.
  TaskEither<DomainFailure, List<ResolvedAttribute>> call({
    required Instance instance,
  }) => _skuRepository.fetchAll().flatMap((skus) {
    final traitIds = <String>[...instance.traitIds];
    for (final sku in skus) {
      if (sku.meta.id == instance.skuId) traitIds.addAll(sku.traitIds);
    }
    return _resolveSchema(traitIds: traitIds);
  });
}
