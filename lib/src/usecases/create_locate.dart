import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'assert_unique_attribute_values.dart';

/// Create a new locate (a place).
///
/// The rules that come with the model apply here exactly as they do to an
/// article's write: a value for an attribute the schema marks unique (a serial
/// number, say) is refused when any other holder — an article, another place, a
/// maker — already holds it. A place is a holder in its own right.
class CreateLocate {
  /// Creates a [CreateLocate] use case.
  const CreateLocate({
    required ILocateRepository locateRepository,
    required AssertUniqueAttributeValues assertUniqueAttributeValues,
    required UnitOfWork unitOfWork,
  }) : _repository = locateRepository,
       _assertUniqueAttributeValues = assertUniqueAttributeValues,
       _unitOfWork = unitOfWork;

  final ILocateRepository _repository;
  final AssertUniqueAttributeValues _assertUniqueAttributeValues;
  final UnitOfWork _unitOfWork;

  /// Executes the use case.
  ///
  /// The rule reads all three holder stores before the row lands, so the check
  /// and the write share the unit of work.
  TaskEither<DomainFailure, Locate> call({required Locate locate}) =>
      TaskEither(
        () => _unitOfWork<DomainFailure, Locate>(
          body: () => _assertUniqueAttributeValues(
            holder: PlaceHolder(locate),
          ).flatMap((_) => _repository.create(locate: locate)).run(),
        ),
      );
}
