import 'package:fpdart/fpdart.dart';

import '../../domain/domain.dart';
import 'in_memory_table.dart';

/// An in-memory [ITraitRepository].
///
/// Records are kept as their JSON rows, so this reference persists exactly the
/// wire form the model round-trips. Nothing here is durable, indexed or
/// thread-safe: it is the smallest backend that satisfies the contract.
class InMemoryTraitRepository
    with InMemoryRowSourceBy<Trait>
    implements ITraitRepository {
  /// Creates an empty [InMemoryTraitRepository].
  InMemoryTraitRepository()
    : table = InMemoryTable<Trait>(
        decode: Trait.fromJson,
        encode: (trait) => trait.toJson(),
        idOf: (trait) => trait.meta.id,
      );

  /// The rows behind this repository — what a transaction snapshots.
  @override
  final InMemoryTable<Trait> table;

  @override
  TaskEither<DomainFailure, List<Trait>> fetchAll() =>
      TaskEither.of(table.all());

  @override
  TaskEither<DomainFailure, Trait> fetchById({required String id}) {
    final found = table.find(id);
    if (found == null) {
      return TaskEither<DomainFailure, Trait>.left(
        NotFoundFailure('Trait "$id" not found'),
      );
    }
    return TaskEither.of(found);
  }

  @override
  TaskEither<DomainFailure, Trait> create({
    required Trait trait,
    IUnitOfWork? uow,
  }) {
    table.put(trait);
    return TaskEither.of(trait);
  }

  @override
  TaskEither<DomainFailure, Trait> update({
    required Trait trait,
    IUnitOfWork? uow,
  }) {
    if (!table.has(trait.meta.id)) {
      return TaskEither<DomainFailure, Trait>.left(
        NotFoundFailure('Trait "${trait.meta.id}" not found'),
      );
    }
    table.put(trait);
    return TaskEither.of(trait);
  }

  @override
  TaskEither<DomainFailure, void> delete({
    required String id,
    IUnitOfWork? uow,
  }) {
    if (!table.remove(id)) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('Trait "$id" not found'),
      );
    }
    return TaskEither.of(null);
  }

  @override
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow}) {
    table.replaceAll(const {});
    return TaskEither.of(null);
  }
}
