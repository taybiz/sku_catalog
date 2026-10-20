import 'package:fpdart/fpdart.dart';

import '../../domain/domain.dart';
import 'in_memory_table.dart';

/// An in-memory [IInstanceRepository].
///
/// Records are kept as their JSON rows, so this reference persists exactly the
/// wire form the model round-trips. Nothing here is durable, indexed or
/// thread-safe: it is the smallest backend that satisfies the contract.
class InMemoryInstanceRepository
    with InMemoryRowSourceBy<Instance>
    implements IInstanceRepository {
  /// Creates an empty [InMemoryInstanceRepository].
  InMemoryInstanceRepository()
    : table = InMemoryTable<Instance>(
        decode: Instance.fromJson,
        encode: (instance) => instance.toJson(),
        idOf: (instance) => instance.meta.id,
      );

  /// The rows behind this repository — what a transaction snapshots.
  @override
  final InMemoryTable<Instance> table;

  @override
  TaskEither<DomainFailure, List<Instance>> fetchAll() =>
      TaskEither.of(table.all());

  @override
  TaskEither<DomainFailure, List<Instance>> fetchByLocate({
    required String? locateId,
  }) => TaskEither.of(
    table.all().where((instance) => instance.locateId == locateId).toList(),
  );

  @override
  TaskEither<DomainFailure, List<Instance>> fetchBySku({
    required String skuId,
  }) => TaskEither.of(
    table.all().where((instance) => instance.skuId == skuId).toList(),
  );

  @override
  TaskEither<DomainFailure, Instance> fetchById({required String id}) {
    final found = table.find(id);
    if (found == null) {
      return TaskEither<DomainFailure, Instance>.left(
        NotFoundFailure('Instance "$id" not found'),
      );
    }
    return TaskEither.of(found);
  }

  @override
  TaskEither<DomainFailure, Instance> create({required Instance instance}) {
    if (table.has(instance.meta.id)) {
      return TaskEither<DomainFailure, Instance>.left(
        AlreadyExistsFailure('Instance "${instance.meta.id}" already exists'),
      );
    }
    table.put(instance);
    return TaskEither.of(instance);
  }

  @override
  TaskEither<DomainFailure, Instance> update({required Instance instance}) {
    if (!table.has(instance.meta.id)) {
      return TaskEither<DomainFailure, Instance>.left(
        NotFoundFailure('Instance "${instance.meta.id}" not found'),
      );
    }
    table.put(instance);
    return TaskEither.of(instance);
  }

  @override
  TaskEither<DomainFailure, void> delete({required String id}) {
    if (!table.remove(id)) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('Instance "$id" not found'),
      );
    }
    return TaskEither.of(null);
  }
}
