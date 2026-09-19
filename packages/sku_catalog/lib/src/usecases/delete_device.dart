import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';
import 'sequence.dart';

/// Deletes a device and the images attached to it.
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
  }) : _deviceRepository = deviceRepository,
       _imageRepository = imageRepository;

  final IDeviceRepository _deviceRepository;
  final IImageRepository _imageRepository;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call(String id) =>
      _imageRepository.fetchAll().flatMap(
        (images) => sequenceTaskEither([
          for (final img in images.where(
            (i) => i.owner == ImageOwner.device && i.ownerId == id,
          ))
            _imageRepository.delete(img.id),
        ]).flatMap((_) => _deviceRepository.delete(id)),
      );
}
