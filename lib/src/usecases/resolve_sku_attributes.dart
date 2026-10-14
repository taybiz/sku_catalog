import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'resolve_attribute_values.dart';
import 'resolve_schema.dart';

/// Resolves the value of every attribute in scope for one SKU, inside the
/// assemblies it belongs to.
///
/// This is the "what does this part owe its assembly" question: a SKU used as a
/// component resolves within each assembly it sits in, so it reports the values it
/// would have in place — the ones it inherits included, [ResolvedAttribute]
/// `inheritedFrom` naming the ancestor they came from. For one article of a SKU,
/// with that article's own layer on top, use `ResolveEffectiveAttributes`.
///
/// [ResolveSchema] answers "which attributes apply, and how are they defined";
/// this answers "what is the value, and who said so".
class ResolveSkuAttributes {
  /// Creates a [ResolveSkuAttributes] use case.
  const ResolveSkuAttributes({
    required ISkuRepository skuRepository,
    required ISkuComponentRepository skuComponentRepository,
    required ResolveSchema resolveSchema,
  }) : _skuRepository = skuRepository,
       _skuComponentRepository = skuComponentRepository,
       _resolveSchema = resolveSchema;

  final ISkuRepository _skuRepository;
  final ISkuComponentRepository _skuComponentRepository;
  final ResolveSchema _resolveSchema;

  /// The shared resolution step, built over this use case's own contracts.
  ///
  /// Built on demand rather than in the constructor: this constructor is `const`,
  /// and a const initializer may not invoke another constructor.
  ResolveAttributeValues get _values => ResolveAttributeValues(
    skuRepository: _skuRepository,
    skuComponentRepository: _skuComponentRepository,
    resolveSchema: _resolveSchema,
  );

  /// Executes the use case.
  TaskEither<DomainFailure, List<ResolvedAttribute>> call({
    required String skuId,
  }) => _values(skuId: skuId);
}
