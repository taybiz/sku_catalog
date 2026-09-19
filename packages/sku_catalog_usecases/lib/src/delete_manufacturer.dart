import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Delete a manufacturer by id, blocked while any SKU uses it.
class DeleteManufacturer {
  /// Creates a [DeleteManufacturer] use case.
  const DeleteManufacturer({
    required IManufacturerRepository manufacturerRepository,
    required IDeviceTypeRepository deviceTypeRepository,
  }) : _manufacturerRepository = manufacturerRepository,
       _deviceTypeRepository = deviceTypeRepository;

  final IManufacturerRepository _manufacturerRepository;
  final IDeviceTypeRepository _deviceTypeRepository;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call(String id) =>
      _deviceTypeRepository.fetchAll().flatMap((types) {
        if (types.any((t) => t.manufacturerId == id)) {
          return TaskEither.left(
            InUseFailure('This manufacturer is in use by one or more SKUs.'),
          );
        }
        return _manufacturerRepository.delete(id);
      });
}
