import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'assert_unique_trait_attribute_value.dart';

/// Create a new attribute definition.
///
/// When the definition is marked [TraitAttributeDefinition.isUnique] the write
/// is rejected with [AlreadyExistsFailure] if any instance that carries the
/// trait already holds a duplicate value for the attribute
/// (see [assertUniqueTraitAttributeValue]).
class CreateTraitAttributeDefinition {
  /// Creates a [CreateTraitAttributeDefinition] use case.
  const CreateTraitAttributeDefinition(
    this._repository, {
    required IInstanceRepository instanceRepository,
  }) : _instanceRepository = instanceRepository;

  final ITraitAttributeDefinitionRepository _repository;
  final IInstanceRepository _instanceRepository;

  /// Executes the use case.
  TaskEither<DomainFailure, TraitAttributeDefinition> call({
    required TraitAttributeDefinition attribute,
  }) => assertUniqueTraitAttributeValue(
    repository: _instanceRepository,
    definition: attribute,
  ).flatMap((_) => _repository.create(attribute: attribute));
}
