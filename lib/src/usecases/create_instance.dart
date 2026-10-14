import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'assert_unique_attribute_values.dart';

/// Create a new instance.
///
/// The rules that come with the model apply here: a value for an attribute its
/// schema marks unique (a serial number, say) is refused when another instance
/// already holds it, so a create cannot quietly mint a second article with the
/// same identity. [AssertUniqueAttributeValues] holds that rule, and a caller
/// builds one and shares it with the other instance write paths.
class CreateInstance {
  /// Creates a [CreateInstance] use case.
  const CreateInstance({
    required IInstanceRepository instanceRepository,
    required AssertUniqueAttributeValues assertUniqueAttributeValues,
  }) : _repository = instanceRepository,
       _assertUniqueAttributeValues = assertUniqueAttributeValues;

  final IInstanceRepository _repository;
  final AssertUniqueAttributeValues _assertUniqueAttributeValues;

  /// Executes the use case.
  TaskEither<DomainFailure, Instance> call({required Instance instance}) =>
      _assertUniqueAttributeValues(
        instance: instance,
      ).flatMap((_) => _repository.create(instance: instance));
}
