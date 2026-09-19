import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch attribute definitions for a trait.
class FetchAttributesByTrait {
  /// Creates a [FetchAttributesByTrait] use case.
  const FetchAttributesByTrait(this._repository);

  final ITraitAttributeDefinitionRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<TraitAttributeDefinition>> call(
    String traitId,
  ) => _repository.fetchByTrait(traitId);
}
