import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch one trait attribute definition by id.
class FetchTraitAttributeDefinitionById {
  /// Creates a [FetchTraitAttributeDefinitionById] use case.
  const FetchTraitAttributeDefinitionById(this._repository);

  final ITraitAttributeDefinitionRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, TraitAttributeDefinition> call(String id) =>
      _repository.fetchById(id);
}
