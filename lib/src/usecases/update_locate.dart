import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'assert_unique_attribute_values.dart';
import 'would_create_tree_cycle.dart';

/// Update an existing locate, refusing parent changes that would loop the
/// locate tree, and refusing a value for an attribute the schema marks unique
/// when any other holder — an article, a place, a maker — already holds it.
class UpdateLocate {
  /// Creates an [UpdateLocate] use case.
  const UpdateLocate({
    required ILocateRepository locateRepository,
    required AssertUniqueAttributeValues assertUniqueAttributeValues,
  }) : _repository = locateRepository,
       _assertUniqueAttributeValues = assertUniqueAttributeValues;

  final ILocateRepository _repository;
  final AssertUniqueAttributeValues _assertUniqueAttributeValues;

  /// Executes the use case.
  TaskEither<DomainFailure, Locate> call({required Locate locate}) =>
      _assertUniqueAttributeValues(holder: PlaceHolder(locate)).flatMap(
        (_) => _repository.fetchById(id: locate.meta.id).flatMap((original) {
          final parentChanged =
              locate.parentLocateId != original.parentLocateId;
          if (!parentChanged) return _repository.update(locate: locate);
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
                  return _repository.update(locate: locate);
                });
          });
        }),
      );
}
