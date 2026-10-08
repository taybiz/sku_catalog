import '../domain/domain.dart';
import 'new_meta.dart';
import 'package:fpdart/fpdart.dart';

import 'would_create_assembly_cycle.dart';

/// Adds a SKU component (BOM edge).
class AddSkuComponent {
  /// Creates an [AddSkuComponent] use case.
  const AddSkuComponent({
    required ISkuComponentRepository repository,
    required ISkuRepository skuRepository,
  }) : _repository = repository,
       _skuRepository = skuRepository;

  final ISkuComponentRepository _repository;
  final ISkuRepository _skuRepository;

  /// Adds a new SKU component linking [parentSkuId] to
  /// [childSkuId].
  TaskEither<DomainFailure, SkuComponent> call({
    required String parentSkuId,
    required String childSkuId,
    required int quantity,
  }) => _skuRepository
      .fetchById(id: parentSkuId)
      .andThen(() => _skuRepository.fetchById(id: childSkuId))
      .flatMap(
        (_) => WouldCreateAssemblyCycle(_repository)(
          parentSkuId: parentSkuId,
          childSkuId: childSkuId,
        ),
      )
      .flatMap((wouldCycle) {
        if (wouldCycle) {
          return TaskEither.left(
            const WouldCreateCycleFailure(
              'Adding this component would create a cycle',
            ),
          );
        }

        // Ids must be unique even for two edges added in the same millisecond:
        // a timestamp is not an identifier.
        final component = SkuComponent(
          meta: newMeta(),
          parentSkuId: parentSkuId,
          childSkuId: childSkuId,
          quantity: quantity,
        );

        return _repository.create(component: component);
      });
}
