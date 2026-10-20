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
    required UnitOfWork unitOfWork,
  }) : _repository = instanceRepository,
       _assertUniqueInstanceName = assertUniqueInstanceName,
       _assertUniqueAttributeValues = assertUniqueAttributeValues,
       _unitOfWork = unitOfWork;

  final IInstanceRepository _repository;
  final AssertUniqueInstanceName _assertUniqueInstanceName;
  final AssertUniqueAttributeValues _assertUniqueAttributeValues;
  final UnitOfWork _unitOfWork;

  /// Executes the use case.
  ///
  /// Both rules read other stores before the row lands — the naming rule reads
  /// every instance, the value rule all three holder stores — so the checks and
  /// the write share the unit of work.
  TaskEither<DomainFailure, Instance> call({required Instance instance}) =>
      TaskEither(
        () => _unitOfWork<DomainFailure, Instance>(
          body: () =>
              _assertUniqueInstanceName(
                    name: instance.name,
                    locateId: instance.locateId,
                  )
                  .flatMap(
                    (_) => _assertUniqueAttributeValues(
                      holder: ArticleHolder(instance),
                    ),
                  )
                  .flatMap((_) => _repository.create(instance: instance))
                  .run(),
        ),
      );
}
