import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'assert_unique_attribute_values.dart';

/// Update an existing manufacturer: a value for an attribute the schema marks
/// unique is refused when any other holder — an article, a place, another maker
/// — already holds it.
class UpdateManufacturer {
  /// Creates an [UpdateManufacturer] use case.
  const UpdateManufacturer({
    required IManufacturerRepository manufacturerRepository,
    required AssertUniqueAttributeValues assertUniqueAttributeValues,
  }) : _repository = manufacturerRepository,
       _assertUniqueAttributeValues = assertUniqueAttributeValues;

  final IManufacturerRepository _repository;
  final AssertUniqueAttributeValues _assertUniqueAttributeValues;

  /// Executes the use case.
  TaskEither<DomainFailure, Manufacturer> call({
    required Manufacturer manufacturer,
  }) => _assertUniqueAttributeValues(
    maker: manufacturer,
  ).flatMap((_) => _repository.update(manufacturer: manufacturer));
}
