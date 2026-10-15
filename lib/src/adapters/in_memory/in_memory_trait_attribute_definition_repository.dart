import 'package:fpdart/fpdart.dart';

import '../../domain/domain.dart';
import 'in_memory_table.dart';

/// An in-memory [ITraitAttributeDefinitionRepository].
///
/// Records are kept as their JSON rows, so this reference persists exactly the
/// wire form the model round-trips. Nothing here is durable, indexed or
/// thread-safe: it is the smallest backend that satisfies the contract.
class InMemoryTraitAttributeDefinitionRepository
    with InMemoryRowSourceBy<TraitAttributeDefinition>
    implements ITraitAttributeDefinitionRepository {
  /// Creates an empty [InMemoryTraitAttributeDefinitionRepository].
  InMemoryTraitAttributeDefinitionRepository()
    : table = InMemoryTable<TraitAttributeDefinition>(
        decode: TraitAttributeDefinition.fromJson,
        encode: (attribute) => attribute.toJson(),
        idOf: (attribute) => attribute.meta.id,
      );

  /// The rows behind this repository — what a transaction snapshots.
  @override
  final InMemoryTable<TraitAttributeDefinition> table;

  @override
  TaskEither<DomainFailure, List<TraitAttributeDefinition>> fetchAll() =>
      TaskEither.of(table.all());

  @override
  TaskEither<DomainFailure, List<TraitAttributeDefinition>> fetchByTrait({
    required String traitId,
  }) => TaskEither.of(
    table.all().where((attribute) => attribute.traitId == traitId).toList(),
  );

  @override
  TaskEither<DomainFailure, TraitAttributeDefinition> fetchById({
    required String id,
  }) {
    final found = table.find(id);
    if (found == null) {
      return TaskEither<DomainFailure, TraitAttributeDefinition>.left(
        NotFoundFailure('TraitAttributeDefinition "$id" not found'),
      );
    }
    return TaskEither.of(found);
  }

  @override
  TaskEither<DomainFailure, TraitAttributeDefinition> create({
    required TraitAttributeDefinition attribute,
    IUnitOfWork? uow,
  }) {
    table.put(attribute);
    return TaskEither.of(attribute);
  }

  @override
  TaskEither<DomainFailure, TraitAttributeDefinition> update({
    required TraitAttributeDefinition attribute,
    IUnitOfWork? uow,
  }) {
    if (!table.has(attribute.meta.id)) {
      return TaskEither<DomainFailure, TraitAttributeDefinition>.left(
        NotFoundFailure(
          'TraitAttributeDefinition "${attribute.meta.id}" not found',
        ),
      );
    }
    table.put(attribute);
    return TaskEither.of(attribute);
  }

  @override
  TaskEither<DomainFailure, void> delete({
    required String id,
    IUnitOfWork? uow,
  }) {
    if (!table.remove(id)) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('TraitAttributeDefinition "$id" not found'),
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
