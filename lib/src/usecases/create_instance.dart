import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'assert_unique_attribute_values.dart';
import 'assert_unique_instance_name.dart';

/// Create a new instance.
///
/// The rules that come with the model apply here, exactly as they do on the
/// update path — a create is not a trusted back door:
///
/// - a name another instance at the same locate already carries (compared
///   case-insensitively) is refused, so the per-locate naming rule holds however
///   the article arrives;
/// - a value for an attribute the schema marks unique (a serial number, say) is
///   refused when another instance already holds it, so a create cannot quietly
///   mint a second article with the same identity.
///
/// [AssertUniqueInstanceName] and [AssertUniqueAttributeValues] hold those rules;
/// a caller builds them once and shares them with the other instance write paths.
class CreateInstance {
  /// Creates a [CreateInstance] use case.
  const CreateInstance({
    required IInstanceRepository instanceRepository,
    required AssertUniqueInstanceName assertUniqueInstanceName,
    required AssertUniqueAttributeValues assertUniqueAttributeValues,
  }) : _repository = instanceRepository,
       _assertUniqueInstanceName = assertUniqueInstanceName,
       _assertUniqueAttributeValues = assertUniqueAttributeValues;

  final IInstanceRepository _repository;
  final AssertUniqueInstanceName _assertUniqueInstanceName;
  final AssertUniqueAttributeValues _assertUniqueAttributeValues;

  /// Executes the use case.
  TaskEither<DomainFailure, Instance> call({required Instance instance}) =>
      _assertUniqueInstanceName(
            name: instance.name,
            locateId: instance.locateId,
          )
          .flatMap((_) => _assertUniqueAttributeValues(instance: instance))
          .flatMap((_) => _repository.create(instance: instance));
}
