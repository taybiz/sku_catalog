import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Create a new attribute definition.
class CreateTraitAttributeDefinition {
  /// Creates a [CreateTraitAttributeDefinition] use case.
  const CreateTraitAttributeDefinition(this._repository);

  final ITraitAttributeDefinitionRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, TraitAttributeDefinition> call(
    TraitAttributeDefinition attribute,
  ) => _repository.create(attribute);
}
