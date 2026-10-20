import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Update an existing trait, refusing parent changes that would loop the
/// trait tree.
class UpdateTrait {
  /// Creates an [UpdateTrait] use case.
  const UpdateTrait(this._repository);

  final ITraitRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Trait> call({required Trait trait}) =>
      _repository.fetchById(id: trait.meta.id).flatMap((original) {
        final parentChanged = trait.parentTraitId != original.parentTraitId;
        if (!parentChanged) return _repository.update(trait: trait);
        return _repository.fetchAll().flatMap((allTraits) {
          final wouldCreate = wouldCreateTreeCycle(
            links: [
              for (final other in allTraits)
                (id: other.meta.id, parentId: other.parentTraitId),
            ],
            nodeId: trait.meta.id,
            parentId: trait.parentTraitId,
          );
          if (wouldCreate) {
            return TaskEither.left(
              WouldCreateCycleFailure(
                'That parent would create a loop in the trait tree.',
              ),
            );
          }
          return _repository.update(trait: trait);
        });
      });
}
