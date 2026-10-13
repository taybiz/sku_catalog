import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'assert_unique_trait_attribute_value.dart';

/// Update an existing trait attribute definition.
///
/// When the definition is marked [TraitAttributeDefinition.isUnique] the write
/// is rejected with [AlreadyExistsFailure] if any instance that carries the
/// trait already holds a duplicate value for the attribute
/// (see [assertUniqueTraitAttributeValue]) — flipping a definition to unique
/// cannot introduce a contradiction with the instance data already stored.
class UpdateTraitAttributeDefinition {
  /// Creates an [UpdateTraitAttributeDefinition] use case.
  const UpdateTraitAttributeDefinition(
    this._repository, {
    required IInstanceRepository instanceRepository,
  }) : _instanceRepository = instanceRepository;

  final ITraitAttributeDefinitionRepository _repository;
  final IInstanceRepository _instanceRepository;

  /// Executes the use case.
  TaskEither<DomainFailure, TraitAttributeDefinition> call({
    required TraitAttributeDefinition definition,
  }) => assertUniqueTraitAttributeValue(
    repository: _instanceRepository,
    definition: definition,
  ).flatMap((_) => _repository.update(attribute: definition));
}
