import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Update an existing manufacturer.
class UpdateManufacturer {
  /// Creates an [UpdateManufacturer] use case.
  const UpdateManufacturer(this._repository);

  final IManufacturerRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Manufacturer> call(Manufacturer manufacturer) =>
      _repository.update(manufacturer);
}
