import 'package:fpdart/fpdart.dart';

import '../../domain/domain.dart';
import 'in_memory_table.dart';

/// An in-memory [ILocateRepository] — the place tree.
///
/// Records are kept as their JSON rows, so this reference persists exactly the
/// wire form the model round-trips. Nothing here is durable, indexed or
/// thread-safe: it is the smallest backend that satisfies the contract.
class InMemoryLocateRepository
    with InMemoryRowSourceBy<Locate>
    implements ILocateRepository {
  /// Creates an empty [InMemoryLocateRepository].
  InMemoryLocateRepository()
    : table = InMemoryTable<Locate>(
        decode: Locate.fromJson,
        encode: (locate) => locate.toJson(),
        idOf: (locate) => locate.meta.id,
      );

  /// The rows behind this repository — what a transaction snapshots.
  @override
  final InMemoryTable<Locate> table;

  @override
  TaskEither<DomainFailure, List<Locate>> fetchAll() =>
      TaskEither.of(table.all());

  @override
  TaskEither<DomainFailure, Locate> fetchById({required String id}) {
    final found = table.find(id);
    if (found == null) {
      return TaskEither<DomainFailure, Locate>.left(
        NotFoundFailure('Locate "$id" not found'),
      );
    }
    return TaskEither.of(found);
  }

  @override
  TaskEither<DomainFailure, Locate> create({required Locate locate}) {
    if (table.has(locate.meta.id)) {
      return TaskEither<DomainFailure, Locate>.left(
        AlreadyExistsFailure('Locate "${locate.meta.id}" already exists'),
      );
    }
    table.put(locate);
    return TaskEither.of(locate);
  }

  @override
  TaskEither<DomainFailure, Locate> update({required Locate locate}) {
    if (!table.has(locate.meta.id)) {
      return TaskEither<DomainFailure, Locate>.left(
        NotFoundFailure('Locate "${locate.meta.id}" not found'),
      );
    }
    table.put(locate);
    return TaskEither.of(locate);
  }

  @override
  TaskEither<DomainFailure, void> delete({required String id}) {
    if (!table.remove(id)) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('Locate "$id" not found'),
      );
    }
    return TaskEither.of(null);
  }
}
