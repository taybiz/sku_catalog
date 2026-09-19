import 'package:fpdart/fpdart.dart';

import '../entities/device_type.dart';
import '../failures/catalog_failures.dart';
import 'unit_of_work.dart';

/// Contract for device type (SKU) persistence.
abstract interface class IDeviceTypeRepository {
  /// Fetch all device types.
  TaskEither<DomainFailure, List<DeviceType>> fetchAll();

  /// Fetch a single device type by id.
  TaskEither<DomainFailure, DeviceType> fetchById(String id);

  /// Create a new device type.
  TaskEither<DomainFailure, DeviceType> create(
    DeviceType deviceType, {
    IUnitOfWork? uow,
  });

  /// Update an existing device type.
  TaskEither<DomainFailure, DeviceType> update(
    DeviceType deviceType, {
    IUnitOfWork? uow,
  });

  /// Delete a device type by id.
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow});

  /// Remove every record (factory reset support).
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow});
}
