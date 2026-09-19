import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Delete an attribute definition by id.
class DeleteTraitAttributeDefinition {
  /// Creates a [DeleteTraitAttributeDefinition] use case.
  const DeleteTraitAttributeDefinition(this._repository);

  final ITraitAttributeDefinitionRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call(String id) => _repository.delete(id);
}
