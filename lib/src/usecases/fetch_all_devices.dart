import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch all devices.
class FetchAllDevices {
  /// Creates a [FetchAllDevices] use case.
  const FetchAllDevices(this._repository);

  final IDeviceRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<Device>> call() => _repository.fetchAll();
}
