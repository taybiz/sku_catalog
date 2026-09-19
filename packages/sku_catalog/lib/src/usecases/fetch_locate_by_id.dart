import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch a single locate by id.
class FetchLocateById {
  /// Creates a [FetchLocateById] use case.
  const FetchLocateById(this._repository);

  final ILocateRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Locate> call(String id) =>
      _repository.fetchById(id);
}
