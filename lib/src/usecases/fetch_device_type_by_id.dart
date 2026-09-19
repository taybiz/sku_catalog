import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch a single device type by id.
class FetchDeviceTypeById {
  /// Creates a [FetchDeviceTypeById] use case.
  const FetchDeviceTypeById(this._repository);

  final IDeviceTypeRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, DeviceType> call(String id) =>
      _repository.fetchById(id);
}
