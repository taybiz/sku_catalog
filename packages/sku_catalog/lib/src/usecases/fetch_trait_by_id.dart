import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch a single trait by id.
class FetchTraitById {
  /// Creates a [FetchTraitById] use case.
  const FetchTraitById(this._repository);

  final ITraitRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Trait> call(String id) => _repository.fetchById(id);
}
