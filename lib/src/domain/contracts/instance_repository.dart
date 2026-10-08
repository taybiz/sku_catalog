import 'package:fpdart/fpdart.dart';

import '../entities/instance.dart';
import '../failures/catalog_failures.dart';
import 'unit_of_work.dart';

/// Contract for instance persistence.
abstract interface class IInstanceRepository {
  /// Fetch all instances.
  TaskEither<DomainFailure, List<Instance>> fetchAll();

  /// Fetch instances belonging to a locate.
  TaskEither<DomainFailure, List<Instance>> fetchByLocate({
    required String locateId,
  });

  /// Fetch a single instance by id.
  TaskEither<DomainFailure, Instance> fetchById({required String id});

  /// Create a new instance.
  TaskEither<DomainFailure, Instance> create({
    required Instance instance,
    IUnitOfWork? uow,
  });

  /// Update an existing instance.
  TaskEither<DomainFailure, Instance> update({
    required Instance instance,
    IUnitOfWork? uow,
  });

  /// Delete an instance by id.
  TaskEither<DomainFailure, void> delete({
    required String id,
    IUnitOfWork? uow,
  });

  /// Remove every record (factory reset support).
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow});
}
