import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

import 'would_create_tree_cycle.dart';

/// Update an existing locate, refusing parent changes that would loop the
/// locate tree.
class UpdateLocate {
  /// Creates an [UpdateLocate] use case.
  const UpdateLocate(this._repository);

  final ILocateRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Locate> call(Locate locate) =>
      _repository.fetchById(locate.meta.id).flatMap((original) {
        final parentChanged = locate.parentLocateId != original.parentLocateId;
        if (!parentChanged) return _repository.update(locate);
        return _repository.fetchAll().flatMap((allLocates) {
          return WouldCreateTreeCycle()
              .call(
                items: [for (final l in allLocates) l.toJson()],
                itemId: locate.meta.id,
                newParentId: locate.parentLocateId ?? '',
                parentKey: 'parent_locate_id',
              )
              .flatMap((wouldCreate) {
                if (wouldCreate) {
                  return TaskEither.left(
                    WouldCreateCycleFailure(
                      'That parent would create a loop in the locate tree.',
                    ),
                  );
                }
                return _repository.update(locate);
              });
        });
      });
}
