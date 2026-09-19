import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Update an existing trait attribute definition.
class UpdateTraitAttributeDefinition {
  /// Creates an [UpdateTraitAttributeDefinition] use case.
  const UpdateTraitAttributeDefinition(this._repository);

  final ITraitAttributeDefinitionRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, TraitAttributeDefinition> call(
    TraitAttributeDefinition definition,
  ) => _repository.update(definition);
}
