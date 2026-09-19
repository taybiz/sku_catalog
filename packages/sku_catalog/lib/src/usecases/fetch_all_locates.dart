import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch all locates.
class FetchAllLocates {
  /// Creates a [FetchAllLocates] use case.
  const FetchAllLocates(this._repository);

  final ILocateRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<Locate>> call() => _repository.fetchAll();
}
