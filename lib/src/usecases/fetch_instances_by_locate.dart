import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch instances belonging to a locate.
class FetchInstancesByLocate {
  /// Creates a [FetchInstancesByLocate] use case.
  const FetchInstancesByLocate(this._repository);

  final IInstanceRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<Instance>> call({required String locateId}) =>
      _repository.fetchByLocate(locateId: locateId);
}
