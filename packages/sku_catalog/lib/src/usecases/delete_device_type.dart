import '../domain/domain.dart';
import 'sequence.dart';
import 'package:fpdart/fpdart.dart';

/// Delete a device type (SKU) by id, blocked while physical devices use it;
/// its component lines cascade.
class DeleteDeviceType {
  /// Creates a [DeleteDeviceType] use case.
  const DeleteDeviceType({
    required IDeviceTypeRepository deviceTypeRepository,
    required IDeviceRepository deviceRepository,
    required ISkuComponentRepository skuComponentRepository,
  }) : _deviceTypeRepository = deviceTypeRepository,
       _deviceRepository = deviceRepository,
       _skuComponentRepository = skuComponentRepository;

  final IDeviceTypeRepository _deviceTypeRepository;
  final IDeviceRepository _deviceRepository;
  final ISkuComponentRepository _skuComponentRepository;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call(String id) =>
      _deviceRepository.fetchAll().flatMap((devices) {
        if (devices.any((d) => d.deviceTypeId == id)) {
          return TaskEither.left(
            InUseFailure('This SKU is in use by one or more devices.'),
          );
        }
        return _skuComponentRepository.fetchAll().flatMap((components) {
          final touching = components
              .where(
                (c) => c.parentDeviceTypeId == id || c.childDeviceTypeId == id,
              )
              .toList();
          return sequenceTaskEither([
            for (final c in touching) _skuComponentRepository.delete(c.meta.id),
          ]).flatMap((_) => _deviceTypeRepository.delete(id));
        });
      });
}
