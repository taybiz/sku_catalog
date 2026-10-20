import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'assert_unique_attribute_values.dart';

/// Create a new manufacturer (a maker).
///
/// The model's rules apply here as they do to an article's write: a value for an
/// attribute the schema marks unique is refused when any other holder — an
/// article, a place, another maker — already holds it. A maker is a holder in
/// its own right.
class CreateManufacturer {
  /// Creates a [CreateManufacturer] use case.
  const CreateManufacturer({
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
      ).flatMap((_) => _repository.create(manufacturer: manufacturer)).run(),
    ),
  );
}
