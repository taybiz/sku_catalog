import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Create a new device type.
class CreateDeviceType {
  /// Creates a [CreateDeviceType] use case.
  const CreateDeviceType(this._repository);

  final IDeviceTypeRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, DeviceType> call(DeviceType deviceType) =>
      _repository.create(deviceType);
}
