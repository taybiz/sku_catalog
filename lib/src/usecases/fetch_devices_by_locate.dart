import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch devices belonging to a locate.
class FetchDevicesByLocate {
  /// Creates a [FetchDevicesByLocate] use case.
  const FetchDevicesByLocate(this._repository);

  final IDeviceRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<Device>> call(String locateId) =>
      _repository.fetchByLocate(locateId);
}
