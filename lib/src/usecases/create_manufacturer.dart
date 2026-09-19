import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Create a new manufacturer.
class CreateManufacturer {
  /// Creates a [CreateManufacturer] use case.
  const CreateManufacturer(this._repository);

  final IManufacturerRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Manufacturer> call(Manufacturer manufacturer) =>
      _repository.create(manufacturer);
}
