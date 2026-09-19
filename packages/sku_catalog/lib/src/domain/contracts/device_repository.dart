import 'package:fpdart/fpdart.dart';

import '../entities/device.dart';
import '../failures/catalog_failures.dart';
import 'unit_of_work.dart';

/// Contract for device persistence.
abstract interface class IDeviceRepository {
  /// Fetch all devices.
  TaskEither<DomainFailure, List<Device>> fetchAll();

  /// Fetch devices belonging to a locate.
  TaskEither<DomainFailure, List<Device>> fetchByLocate(String locateId);

  /// Fetch a single device by id.
  TaskEither<DomainFailure, Device> fetchById(String id);

  /// Create a new device.
  TaskEither<DomainFailure, Device> create(Device device, {IUnitOfWork? uow});

  /// Update an existing device.
  TaskEither<DomainFailure, Device> update(Device device, {IUnitOfWork? uow});

  /// Delete a device by id.
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow});

  /// Remove every record (factory reset support).
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow});
}
