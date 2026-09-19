import 'package:fpdart/fpdart.dart';

import '../entities/sku_component.dart';
import '../failures/catalog_failures.dart';
import 'unit_of_work.dart';

/// Contract for SKU component persistence.
abstract interface class ISkuComponentRepository {
  /// Fetch all SKU components.
  TaskEither<DomainFailure, List<SkuComponent>> fetchAll();

  /// Fetch components for device type.
  TaskEither<DomainFailure, List<SkuComponent>> fetchByDeviceType(
    String deviceTypeId,
  );

  /// Fetch a single component by id.
  TaskEither<DomainFailure, SkuComponent> fetchById(String id);

  /// Create a new SKU component.
  TaskEither<DomainFailure, SkuComponent> create(
    SkuComponent component, {
    IUnitOfWork? uow,
  });

  /// Delete a SKU component by id.
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow});

  /// Remove every record (factory reset support).
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow});
}
