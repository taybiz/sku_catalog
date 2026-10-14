import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'resolve_attribute_values.dart';
import 'resolve_schema.dart';

/// Resolves the value of every attribute in scope for one instance, its own layer
/// included.
///
/// [ResolveSchema] answers "which attributes apply, and how are they defined";
/// this answers "what is the value, and who said so" — precedence is the instance,
/// then the SKU it instantiates, then the SKUs above it in an assembly (nearest
/// first, so a component can inherit what the assembly sets), then the
/// definition's own default. `ResolvedAttribute.source` names the winner and
/// `inheritedFrom` names the ancestor a value came from.
///
/// The model-only question — "what does this part owe its assembly" — is its own
/// use case, `ResolveSkuAttributes`.
class ResolveEffectiveAttributes {
  /// Creates a [ResolveEffectiveAttributes] use case.
  const ResolveEffectiveAttributes({
    required IInstanceRepository instanceRepository,
    required ISkuRepository skuRepository,
    required ISkuComponentRepository skuComponentRepository,
    required ResolveSchema resolveSchema,
  }) : _instanceRepository = instanceRepository,
       _skuRepository = skuRepository,
       _skuComponentRepository = skuComponentRepository,
       _resolveSchema = resolveSchema;

  final IInstanceRepository _instanceRepository;
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
    required String instanceId,
  }) => _instanceRepository
      .fetchById(id: instanceId)
      .flatMap(
        (instance) => _values(
          skuId: instance.skuId,
          traitIds: instance.traitIds,
          instance: instance,
        ),
      );
}
