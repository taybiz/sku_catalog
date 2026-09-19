import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

import 'would_create_tree_cycle.dart';

/// Update an existing trait, refusing parent changes that would loop the
/// trait tree.
class UpdateTrait {
  /// Creates an [UpdateTrait] use case.
  const UpdateTrait(this._repository);

  final ITraitRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Trait> call(Trait trait) =>
      _repository.fetchById(trait.meta.id).flatMap((original) {
        final parentChanged = trait.parentTraitId != original.parentTraitId;
        if (!parentChanged) return _repository.update(trait);
        return _repository.fetchAll().flatMap((allTraits) {
          return WouldCreateTreeCycle()
              .call(
                items: [for (final t in allTraits) t.toJson()],
                itemId: trait.meta.id,
                newParentId: trait.parentTraitId ?? '',
                parentKey: 'parent_trait_id',
              )
              .flatMap((wouldCreate) {
                if (wouldCreate) {
                  return TaskEither.left(
                    WouldCreateCycleFailure(
                      'That parent would create a loop in the trait tree.',
                    ),
                  );
                }
                return _repository.update(trait);
              });
        });
      });
}
