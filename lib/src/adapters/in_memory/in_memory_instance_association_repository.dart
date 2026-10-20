import 'package:fpdart/fpdart.dart';

import '../../domain/domain.dart';
import 'in_memory_table.dart';

/// An in-memory [IInstanceAssociationRepository] — the labeled relationship
/// edges between articles.
///
/// Records are kept as their JSON rows, so this reference persists exactly the
/// wire form the model round-trips. Nothing here is durable, indexed or
/// thread-safe: it is the smallest backend that satisfies the contract.
class InMemoryInstanceAssociationRepository
    with InMemoryRowSourceBy<InstanceAssociation>
    implements IInstanceAssociationRepository {
  /// Creates an empty [InMemoryInstanceAssociationRepository].
  InMemoryInstanceAssociationRepository()
    : table = InMemoryTable<InstanceAssociation>(
        decode: InstanceAssociation.fromJson,
        encode: (association) => association.toJson(),
        idOf: (association) => association.meta.id,
      );

  /// The rows behind this repository — what a transaction snapshots.
  @override
  final InMemoryTable<InstanceAssociation> table;

  @override
  TaskEither<DomainFailure, List<InstanceAssociation>> fetchAll() =>
      TaskEither.of(table.all());

  @override
  TaskEither<DomainFailure, List<InstanceAssociation>> fetchByInstance({
    required String instanceId,
    String? kind,
  }) => TaskEither.of(
    table
        .all()
        .where(
          (association) =>
              (association.sourceInstanceId == instanceId ||
                  association.targetInstanceId == instanceId) &&
              (kind == null || association.kind == kind),
        )
        .toList(),
  );

  @override
  TaskEither<DomainFailure, InstanceAssociation> fetchById({
    required String id,
  }) {
    final found = table.find(id);
    if (found == null) {
      return TaskEither<DomainFailure, InstanceAssociation>.left(
        NotFoundFailure('InstanceAssociation "$id" not found'),
      );
    }
    return TaskEither.of(found);
  }

  @override
  TaskEither<DomainFailure, InstanceAssociation> create({
    required InstanceAssociation association,
  }) {
    if (table.has(association.meta.id)) {
      return TaskEither<DomainFailure, InstanceAssociation>.left(
        AlreadyExistsFailure(
          'InstanceAssociation "${association.meta.id}" already exists',
        ),
      );
    }
    table.put(association);
    return TaskEither.of(association);
  }

  @override
  TaskEither<DomainFailure, void> delete({required String id}) {
    if (!table.remove(id)) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('InstanceAssociation "$id" not found'),
      );
    }
    return TaskEither.of(null);
  }
}
