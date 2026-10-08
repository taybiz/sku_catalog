import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch all instances.
class FetchAllInstances {
  /// Creates a [FetchAllInstances] use case.
  const FetchAllInstances(this._repository);

  final IInstanceRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<Instance>> call() => _repository.fetchAll();
}
