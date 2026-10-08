import 'package:fpdart/fpdart.dart';

import '../entities/locate.dart';
import '../failures/catalog_failures.dart';
import 'unit_of_work.dart';

/// Contract for locate persistence.
abstract interface class ILocateRepository {
  /// Fetch all locates.
  TaskEither<DomainFailure, List<Locate>> fetchAll();

  /// Fetch a single locate by id.
  TaskEither<DomainFailure, Locate> fetchById({required String id});

  /// Create a new locate.
  TaskEither<DomainFailure, Locate> create({
    required Locate locate,
    IUnitOfWork? uow,
  });

  /// Update an existing locate.
  TaskEither<DomainFailure, Locate> update({
    required Locate locate,
    IUnitOfWork? uow,
  });

  /// Delete a locate by id.
  TaskEither<DomainFailure, void> delete({
    required String id,
    IUnitOfWork? uow,
  });

  /// Remove every record (factory reset support).
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow});
}
