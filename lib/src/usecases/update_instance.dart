import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';
import 'assert_unique_attribute_values.dart';
import 'assert_unique_instance_name.dart';

/// Updates an existing instance: its name stays unique within its locate, and a
/// value for an attribute the schema marks unique stays unique across the catalog.
///
/// The rules are the model's, and they are the whole job — which articles carry a
/// place and which leave it unset is the consumer's convention, so the catalog
/// stores the locate it is handed. A record nobody stored fails with
/// [NotFoundFailure].
class UpdateInstance {
  /// Creates an [UpdateInstance] use case.
  const UpdateInstance({
    required IInstanceRepository instanceRepository,
    required AssertUniqueInstanceName assertUniqueInstanceName,
    required AssertUniqueAttributeValues assertUniqueAttributeValues,
  }) : _instanceRepository = instanceRepository,
       _assertUniqueInstanceName = assertUniqueInstanceName,
       _assertUniqueAttributeValues = assertUniqueAttributeValues;

  final IInstanceRepository _instanceRepository;
  final AssertUniqueInstanceName _assertUniqueInstanceName;
  final AssertUniqueAttributeValues _assertUniqueAttributeValues;

  /// Executes the use case.
  TaskEither<DomainFailure, Instance> call({
    required Instance instance,
  }) => _instanceRepository
      .fetchById(id: instance.meta.id)
      .flatMap(
        (_) =>
            _assertUniqueInstanceName(
                  name: instance.name,
                  locateId: instance.locateId,
                  excludeId: instance.meta.id,
                )
                .flatMap((_) => _assertUniqueAttributeValues(article: instance))
                .flatMap((_) => _instanceRepository.update(instance: instance)),
      );
}
