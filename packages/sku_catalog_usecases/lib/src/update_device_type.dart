import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Update an existing device type.
class UpdateDeviceType {
  /// Creates an [UpdateDeviceType] use case.
  const UpdateDeviceType(this._repository);

  final IDeviceTypeRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, DeviceType> call(DeviceType deviceType) =>
      _repository.update(deviceType);
}
