import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Create a new trait.
class CreateTrait {
  /// Creates a [CreateTrait] use case.
  const CreateTrait(this._repository);

  final ITraitRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Trait> call(Trait trait) =>
      _repository.create(trait);
}
