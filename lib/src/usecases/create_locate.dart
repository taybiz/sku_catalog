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
  }) : _repository = locateRepository,
       _assertUniqueAttributeValues = assertUniqueAttributeValues;

  final ILocateRepository _repository;
  final AssertUniqueAttributeValues _assertUniqueAttributeValues;

  /// Executes the use case.
  TaskEither<DomainFailure, Locate> call({required Locate locate}) =>
      _assertUniqueAttributeValues(
        holder: PlaceHolder(locate),
      ).flatMap((_) => _repository.create(locate: locate));
}
