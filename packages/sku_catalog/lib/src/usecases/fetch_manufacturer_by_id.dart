import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch a single manufacturer by id.
class FetchManufacturerById {
  /// Creates a [FetchManufacturerById] use case.
  const FetchManufacturerById(this._repository);

  final IManufacturerRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Manufacturer> call(String id) =>
      _repository.fetchById(id);
}
