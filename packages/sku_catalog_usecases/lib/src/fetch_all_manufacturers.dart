import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch all manufacturers.
class FetchAllManufacturers {
  /// Creates a [FetchAllManufacturers] use case.
  const FetchAllManufacturers(this._repository);

  final IManufacturerRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<Manufacturer>> call() =>
      _repository.fetchAll();
}
