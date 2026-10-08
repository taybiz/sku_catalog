import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch a single instance by id.
class FetchInstanceById {
  /// Creates a [FetchInstanceById] use case.
  const FetchInstanceById(this._repository);

  final IInstanceRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Instance> call(String id) =>
      _repository.fetchById(id);
}
