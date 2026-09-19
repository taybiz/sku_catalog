import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch all trait attribute definitions.
class FetchAllTraitAttributeDefinitions {
  /// Creates a [FetchAllTraitAttributeDefinitions] use case.
  const FetchAllTraitAttributeDefinitions(this._repository);

  final ITraitAttributeDefinitionRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<TraitAttributeDefinition>> call() =>
      _repository.fetchAll();
}
