import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch a single device by id.
class FetchDeviceById {
  /// Creates a [FetchDeviceById] use case.
  const FetchDeviceById(this._repository);

  final IDeviceRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Device> call(String id) =>
      _repository.fetchById(id);
}
