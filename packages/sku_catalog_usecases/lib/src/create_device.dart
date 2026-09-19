import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Create a new device.
class CreateDevice {
  /// Creates a [CreateDevice] use case.
  const CreateDevice(this._repository);

  final IDeviceRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Device> call(Device device) =>
      _repository.create(device);
}
