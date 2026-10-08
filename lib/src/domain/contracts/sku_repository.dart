import 'package:fpdart/fpdart.dart';

import '../entities/sku.dart';
import '../failures/catalog_failures.dart';
import 'unit_of_work.dart';

/// Contract for SKU persistence.
abstract interface class ISkuRepository {
  /// Fetch all SKUs.
  TaskEither<DomainFailure, List<Sku>> fetchAll();

  /// Fetch a single SKU by id.
  TaskEither<DomainFailure, Sku> fetchById(String id);

  /// Create a new SKU.
  TaskEither<DomainFailure, Sku> create(Sku sku, {IUnitOfWork? uow});

  /// Update an existing SKU.
  TaskEither<DomainFailure, Sku> update(Sku sku, {IUnitOfWork? uow});

  /// Delete a SKU by id.
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow});

  /// Remove every record (factory reset support).
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow});
}
