import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'instance_naming.dart';

/// Fails with [AlreadyExistsFailure] when another instance at [locateId]
/// already carries [name] (case-insensitive), excluding [excludeId].
///
/// The per-locate unique name rule lives here so [UpdateInstance] and any
/// caller's own creation use case share one implementation.
TaskEither<DomainFailure, Unit> assertUniqueInstanceName(
  IInstanceRepository repository, {
  required String name,
  required String? locateId,
  String? excludeId,
}) => repository.fetchAll().flatMap((all) {
  final clash = all.any(
    (d) =>
        d.meta.id != excludeId &&
        d.locateId == locateId &&
        namesClash(d.name, name),
  );
  if (clash) {
    return TaskEither.left(
      AlreadyExistsFailure(
        'An instance named "$name" already exists at this locate',
      ),
    );
  }
  return TaskEither.of(unit);
});
