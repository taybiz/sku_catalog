import 'package:fpdart/fpdart.dart';

import '../../domain/domain.dart';
import 'in_memory_table.dart';

/// An in-memory [ISkuComponentRepository] — the assembly edges.
///
/// Records are kept as their JSON rows, so this reference persists exactly the
/// wire form the model round-trips. Nothing here is durable, indexed or
/// thread-safe: it is the smallest backend that satisfies the contract.
class InMemorySkuComponentRepository
    with InMemoryRowSourceBy<SkuComponent>
    implements ISkuComponentRepository {
  /// Creates an empty [InMemorySkuComponentRepository].
  InMemorySkuComponentRepository()
    : table = InMemoryTable<SkuComponent>(
        decode: SkuComponent.fromJson,
        encode: (component) => component.toJson(),
        idOf: (component) => component.meta.id,
      );

  /// The rows behind this repository — what a transaction snapshots.
  @override
  final InMemoryTable<SkuComponent> table;

  @override
  TaskEither<DomainFailure, List<SkuComponent>> fetchAll() =>
      TaskEither.of(table.all());

  @override
  TaskEither<DomainFailure, List<SkuComponent>> fetchBySku({
    required String skuId,
  }) => TaskEither.of(
    table.all().where((component) => component.parentSkuId == skuId).toList(),
  );

  @override
  TaskEither<DomainFailure, SkuComponent> fetchById({required String id}) {
    final found = table.find(id);
    if (found == null) {
      return TaskEither<DomainFailure, SkuComponent>.left(
        NotFoundFailure('SkuComponent "$id" not found'),
      );
    }
    return TaskEither.of(found);
  }

  @override
  TaskEither<DomainFailure, SkuComponent> create({
    required SkuComponent component,
    IUnitOfWork? uow,
  }) {
    table.put(component);
    return TaskEither.of(component);
  }

  @override
  TaskEither<DomainFailure, void> delete({
    required String id,
    IUnitOfWork? uow,
  }) {
    if (!table.remove(id)) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('SkuComponent "$id" not found'),
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
