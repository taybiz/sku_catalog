import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Runs [tasks] in order, collecting their right values; the first failure
/// short-circuits and is preserved.
TaskEither<DomainFailure, List<T>> sequenceTaskEither<T>(
  List<TaskEither<DomainFailure, T>> tasks,
) => tasks.fold<TaskEither<DomainFailure, List<T>>>(
  TaskEither.of(const []),
  (acc, task) => acc.flatMap((list) => task.map((v) => [...list, v])),
);
