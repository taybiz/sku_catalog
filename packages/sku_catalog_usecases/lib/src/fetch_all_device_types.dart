import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch all device types.
class FetchAllDeviceTypes {
  /// Creates a [FetchAllDeviceTypes] use case.
  const FetchAllDeviceTypes(this._repository);

  final IDeviceTypeRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<DeviceType>> call() => _repository.fetchAll();
}
