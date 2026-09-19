import 'package:fpdart/fpdart.dart';

import '../entities/manufacturer.dart';
import '../failures/catalog_failures.dart';
import 'unit_of_work.dart';

/// Contract for manufacturer persistence.
abstract interface class IManufacturerRepository {
  /// Fetch all manufacturers.
  TaskEither<DomainFailure, List<Manufacturer>> fetchAll();

  /// Fetch a single manufacturer by id.
  TaskEither<DomainFailure, Manufacturer> fetchById(String id);

  /// Create a new manufacturer.
  TaskEither<DomainFailure, Manufacturer> create(
    Manufacturer manufacturer, {
    IUnitOfWork? uow,
  });

  /// Update an existing manufacturer.
  TaskEither<DomainFailure, Manufacturer> update(
    Manufacturer manufacturer, {
    IUnitOfWork? uow,
  });

  /// Delete a manufacturer by id.
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow});

  /// Remove every record (factory reset support).
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow});
}
