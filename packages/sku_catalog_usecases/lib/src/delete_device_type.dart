import 'package:fpdart/fpdart.dart';
import 'package:sku_catalog_domain/sku_catalog_domain.dart';

import 'sequence.dart';

/// Delete a device type (SKU) by id, blocked while physical devices use it; its
/// component lines cascade.
///
/// Two writes happen here — the assembly lines that referenced the SKU, then the
/// SKU itself — so pass a [unitOfWork] when your store can roll back: a failed
/// delete must not leave the assembly already disassembled.
class DeleteDeviceType {
  /// Creates a [DeleteDeviceType] use case.
  const DeleteDeviceType({
    required IDeviceTypeRepository deviceTypeRepository,
    required IDeviceRepository deviceRepository,
    required ISkuComponentRepository skuComponentRepository,
    IUnitOfWork? unitOfWork,
  }) : _deviceTypeRepository = deviceTypeRepository,
       _deviceRepository = deviceRepository,
       _skuComponentRepository = skuComponentRepository,
       _unitOfWork = unitOfWork ?? const NoOpUnitOfWork();

  final IDeviceTypeRepository _deviceTypeRepository;
  final IDeviceRepository _deviceRepository;
  final ISkuComponentRepository _skuComponentRepository;
  final IUnitOfWork _unitOfWork;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call(
    String id,
  ) => _deviceRepository.fetchAll().flatMap((devices) {
    if (devices.any((d) => d.deviceTypeId == id)) {
      return TaskEither.left(
        InUseFailure('This SKU is in use by one or more devices.'),
      );
    }
    return _skuComponentRepository.fetchAll().flatMap((components) {
      final touching = components
          .where((c) => c.parentDeviceTypeId == id || c.childDeviceTypeId == id)
          .toList();
      // TaskEither's raw constructor takes an async Either, which is what
      // runEither produces. TaskEither.tryCatch would take the Either as a
      // *success* value and hand back Right(Left(...)).
      return TaskEither<DomainFailure, void>(
        () => _unitOfWork.runEither<DomainFailure, void>(
          () => sequenceTaskEither([
            for (final c in touching) _skuComponentRepository.delete(c.meta.id),
          ]).flatMap((_) => _deviceTypeRepository.delete(id)).run(),
        ),
      );
    });
  });
}
