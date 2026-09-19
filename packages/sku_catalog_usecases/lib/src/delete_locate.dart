import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Delete a locate by id, blocked while it still has sub-locates or assigned
/// devices.
class DeleteLocate {
  /// Creates a [DeleteLocate] use case.
  const DeleteLocate({
    required ILocateRepository locateRepository,
    required IDeviceRepository deviceRepository,
  }) : _locateRepository = locateRepository,
       _deviceRepository = deviceRepository;

  final ILocateRepository _locateRepository;
  final IDeviceRepository _deviceRepository;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call(String id) =>
      _locateRepository.fetchAll().flatMap((locates) {
        if (locates.any((l) => l.parentLocateId == id)) {
          return TaskEither.left(InUseFailure('This locate has sub-locates.'));
        }
        return _deviceRepository.fetchAll().flatMap((devices) {
          if (devices.any((d) => d.locateId == id)) {
            return TaskEither.left(
              InUseFailure('This locate has assigned devices.'),
            );
          }
          return _locateRepository.delete(id);
        });
      });
}
