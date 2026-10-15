import 'package:fpdart/fpdart.dart';

import '../../domain/domain.dart';
import 'in_memory_table.dart';

/// An in-memory [ISkuRepository].
///
/// Records are kept as their JSON rows, so this reference persists exactly the
/// wire form the model round-trips. Nothing here is durable, indexed or
/// thread-safe: it is the smallest backend that satisfies the contract.
class InMemorySkuRepository
    with InMemoryRowSourceBy<Sku>
    implements ISkuRepository {
  /// Creates an empty [InMemorySkuRepository].
  InMemorySkuRepository()
    : table = InMemoryTable<Sku>(
        decode: Sku.fromJson,
        encode: (sku) => sku.toJson(),
        idOf: (sku) => sku.meta.id,
      );

  /// The rows behind this repository — what a transaction snapshots.
  @override
  final InMemoryTable<Sku> table;

  @override
  TaskEither<DomainFailure, List<Sku>> fetchAll() => TaskEither.of(table.all());

  @override
  TaskEither<DomainFailure, Sku> fetchById({required String id}) {
    final found = table.find(id);
    if (found == null) {
      return TaskEither<DomainFailure, Sku>.left(
        NotFoundFailure('Sku "$id" not found'),
      );
    }
    return TaskEither.of(found);
  }

  @override
  TaskEither<DomainFailure, Sku> create({required Sku sku, IUnitOfWork? uow}) {
    table.put(sku);
    return TaskEither.of(sku);
  }

  @override
  TaskEither<DomainFailure, Sku> update({required Sku sku, IUnitOfWork? uow}) {
    if (!table.has(sku.meta.id)) {
      return TaskEither<DomainFailure, Sku>.left(
        NotFoundFailure('Sku "${sku.meta.id}" not found'),
      );
    }
    table.put(sku);
    return TaskEither.of(sku);
  }

  @override
  TaskEither<DomainFailure, void> delete({
    required String id,
    IUnitOfWork? uow,
  }) {
    if (!table.remove(id)) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('Sku "$id" not found'),
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
