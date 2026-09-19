import 'package:fpdart/fpdart.dart';
import 'package:sku_catalog_domain/sku_catalog_domain.dart';

import 'sequence.dart';

/// Deletes a device and the images attached to it.
///
/// Two writes — the images, then the device — so pass a [unitOfWork] when your
/// store can roll back.
///
/// Anything *outside* the catalog that references a device — a wiring graph, a
/// bill of materials, a harness — is that consumer's to cascade. Deleting
/// through this use case leaves those references dangling by design: the
/// catalog does not know they exist. Compose your own deletion around this one.
class DeleteDevice {
  /// Creates a [DeleteDevice] use case.
  const DeleteDevice({
    required IDeviceRepository deviceRepository,
    required IImageRepository imageRepository,
    IUnitOfWork? unitOfWork,
  }) : _deviceRepository = deviceRepository,
       _imageRepository = imageRepository,
       _unitOfWork = unitOfWork ?? const NoOpUnitOfWork();

  final IDeviceRepository _deviceRepository;
  final IImageRepository _imageRepository;
  final IUnitOfWork _unitOfWork;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call(String id) =>
      _imageRepository.fetchAll().flatMap((images) {
        final mine = images
            .where((i) => i.owner == ImageOwner.device && i.ownerId == id)
            .toList();
        return TaskEither<DomainFailure, void>(
          () => _unitOfWork.runEither<DomainFailure, void>(
            () => sequenceTaskEither([
              for (final img in mine) _imageRepository.delete(img.id),
            ]).flatMap((_) => _deviceRepository.delete(id)).run(),
          ),
        );
      });
}
