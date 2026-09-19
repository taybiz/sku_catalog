import '../domain/domain.dart';
import 'new_meta.dart';
import 'package:fpdart/fpdart.dart';

import 'would_create_assembly_cycle.dart';

/// Adds a SKU component (BOM edge).
class AddSkuComponent {
  /// Creates an [AddSkuComponent] use case.
  const AddSkuComponent({
    required ISkuComponentRepository repository,
    required IDeviceTypeRepository deviceTypeRepository,
  }) : _repository = repository,
       _deviceTypeRepository = deviceTypeRepository;

  final ISkuComponentRepository _repository;
  final IDeviceTypeRepository _deviceTypeRepository;

  /// Adds a new SKU component linking [parentDeviceTypeId] to
  /// [childDeviceTypeId].
  TaskEither<DomainFailure, SkuComponent> call({
    required String parentDeviceTypeId,
    required String childDeviceTypeId,
    required int quantity,
  }) => _deviceTypeRepository
      .fetchById(parentDeviceTypeId)
      .andThen(() => _deviceTypeRepository.fetchById(childDeviceTypeId))
      .flatMap(
        (_) => WouldCreateAssemblyCycle(_repository)(
          parentDeviceTypeId,
          childDeviceTypeId,
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
          parentDeviceTypeId: parentDeviceTypeId,
          childDeviceTypeId: childDeviceTypeId,
          quantity: quantity,
        );

        return _repository.create(component);
      });
}
