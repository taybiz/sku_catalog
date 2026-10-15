import 'package:fpdart/fpdart.dart';

import '../../domain/domain.dart';
import 'in_memory_table.dart';

/// An in-memory [ISkuAssociationRepository] — the labeled relationship edges.
///
/// Records are kept as their JSON rows, so this reference persists exactly the
/// wire form the model round-trips. Nothing here is durable, indexed or
/// thread-safe: it is the smallest backend that satisfies the contract.
class InMemorySkuAssociationRepository
    with InMemoryRowSourceBy<SkuAssociation>
    implements ISkuAssociationRepository {
  /// Creates an empty [InMemorySkuAssociationRepository].
  InMemorySkuAssociationRepository()
    : table = InMemoryTable<SkuAssociation>(
        decode: SkuAssociation.fromJson,
        encode: (association) => association.toJson(),
        idOf: (association) => association.meta.id,
      );

  /// The rows behind this repository — what a transaction snapshots.
  @override
  final InMemoryTable<SkuAssociation> table;

  @override
  TaskEither<DomainFailure, List<SkuAssociation>> fetchAll() =>
      TaskEither.of(table.all());

  @override
  TaskEither<DomainFailure, List<SkuAssociation>> fetchBySku({
    required String skuId,
    String? kind,
  }) => TaskEither.of(
    table
        .all()
        .where(
          (association) =>
              (association.sourceSkuId == skuId ||
                  association.targetSkuId == skuId) &&
              (kind == null || association.kind == kind),
        )
        .toList(),
  );

  @override
  TaskEither<DomainFailure, SkuAssociation> fetchById({required String id}) {
    final found = table.find(id);
    if (found == null) {
      return TaskEither<DomainFailure, SkuAssociation>.left(
        NotFoundFailure('SkuAssociation "$id" not found'),
      );
    }
    return TaskEither.of(found);
  }

  @override
  TaskEither<DomainFailure, SkuAssociation> create({
    required SkuAssociation association,
    IUnitOfWork? uow,
  }) {
    table.put(association);
    return TaskEither.of(association);
  }

  @override
  TaskEither<DomainFailure, void> delete({
    required String id,
    IUnitOfWork? uow,
  }) {
    if (!table.remove(id)) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('SkuAssociation "$id" not found'),
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
