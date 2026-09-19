import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch components for a device type.
class FetchSkuComponentsByDeviceType {
  /// Creates a [FetchSkuComponentsByDeviceType] use case.
  const FetchSkuComponentsByDeviceType(this._repository);

  final ISkuComponentRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<SkuComponent>> call(String deviceTypeId) =>
      _repository.fetchByDeviceType(deviceTypeId);
}
