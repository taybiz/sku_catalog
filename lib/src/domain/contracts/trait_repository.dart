import 'package:fpdart/fpdart.dart';

import '../entities/trait.dart';
import '../failures/catalog_failures.dart';
import 'unit_of_work.dart';

/// Contract for trait persistence.
abstract interface class ITraitRepository {
  /// Fetch all traits.
  TaskEither<DomainFailure, List<Trait>> fetchAll();

  /// Fetch a single trait by id.
  TaskEither<DomainFailure, Trait> fetchById(String id);

  /// Create a new trait.
  TaskEither<DomainFailure, Trait> create(Trait trait, {IUnitOfWork? uow});

  /// Update an existing trait.
  TaskEither<DomainFailure, Trait> update(Trait trait, {IUnitOfWork? uow});

  /// Delete a trait by id.
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow});

  /// Remove every record (factory reset support).
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow});
}
