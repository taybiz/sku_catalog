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
    required UnitOfWork unitOfWork,
  }) : _repository = locateRepository,
       _assertUniqueAttributeValues = assertUniqueAttributeValues,
       _unitOfWork = unitOfWork;

  final ILocateRepository _repository;
  final AssertUniqueAttributeValues _assertUniqueAttributeValues;
  final UnitOfWork _unitOfWork;

  /// Executes the use case.
  ///
  /// The unique-value rule reads all three holder stores and the cycle guard
  /// reads the whole locate tree, so both checks and the write share the unit of
  /// work rather than racing it.
  TaskEither<DomainFailure, Locate> call({
    required Locate locate,
  }) => TaskEither(
    () => _unitOfWork<DomainFailure, Locate>(
      body: () => _assertUniqueAttributeValues(holder: PlaceHolder(locate))
          .flatMap(
            (_) => _repository.fetchById(id: locate.meta.id).flatMap((
              original,
            ) {
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
                        return TaskEither<DomainFailure, Locate>.left(
                          WouldCreateCycleFailure(
                            'That parent would create a loop in the locate tree.',
                          ),
                        );
                      }
                      return _repository.update(locate: locate);
                    });
              });
            }),
          )
          .run(),
    ),
  );
}
