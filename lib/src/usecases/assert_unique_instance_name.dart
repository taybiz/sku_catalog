import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';

/// Fails with [AlreadyExistsFailure] when another instance at the same locate
/// already carries the name (case-insensitive).
///
/// The per-locate unique name rule lives here so [UpdateInstance] and any
/// caller's own naming flow share one implementation.
class AssertUniqueInstanceName {
  /// Creates an [AssertUniqueInstanceName] use case.
  const AssertUniqueInstanceName(this._repository);

  final IInstanceRepository _repository;

  /// Executes the use case: checks [name] at [locateId], ignoring the instance
  /// [excludeId] when an existing article is being renamed.
  TaskEither<DomainFailure, Unit> call({
    required String name,
    required String? locateId,
    String? excludeId,
  }) => _repository.fetchByLocate(locateId: locateId).flatMap((all) {
    final clash = all.any(
      (instance) =>
          instance.meta.id != excludeId &&
          instance.locateId == locateId &&
          namesClash(a: instance.name, b: name),
    );
    if (clash) {
      return TaskEither<DomainFailure, Unit>.left(
        AlreadyExistsFailure(
          'An instance named "$name" already exists at this locate',
        ),
      );
    }
    return TaskEither<DomainFailure, Unit>.of(unit);
  });
}
