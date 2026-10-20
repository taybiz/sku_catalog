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
    required UnitOfWork unitOfWork,
  }) : _repository = manufacturerRepository,
       _assertUniqueAttributeValues = assertUniqueAttributeValues,
       _unitOfWork = unitOfWork;

  final IManufacturerRepository _repository;
  final AssertUniqueAttributeValues _assertUniqueAttributeValues;
  final UnitOfWork _unitOfWork;

  /// Executes the use case.
  ///
  /// The rule reads all three holder stores before the row lands, so the check
  /// and the write share the unit of work.
  TaskEither<DomainFailure, Manufacturer> call({
    required Manufacturer manufacturer,
  }) => TaskEither(
    () => _unitOfWork<DomainFailure, Manufacturer>(
      body: () => _assertUniqueAttributeValues(
        holder: MakerHolder(manufacturer),
      ).flatMap((_) => _repository.update(manufacturer: manufacturer)).run(),
    ),
  );
}
