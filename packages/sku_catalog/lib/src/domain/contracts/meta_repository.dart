import 'package:fpdart/fpdart.dart';

import '../entities/meta.dart';
import '../failures/catalog_failures.dart';
import 'unit_of_work.dart';

/// Contract for meta (bundle metadata) persistence.
abstract interface class IMetaRepository {
  /// Fetch the current meta.
  TaskEither<DomainFailure, Meta> fetch();

  /// Update meta.
  TaskEither<DomainFailure, Meta> update(Meta meta, {IUnitOfWork? uow});

  /// Remove the current meta (factory reset support).
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow});
}
