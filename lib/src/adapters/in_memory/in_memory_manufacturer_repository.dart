import 'package:fpdart/fpdart.dart';

import '../../domain/domain.dart';
import 'in_memory_table.dart';

/// An in-memory [IManufacturerRepository].
///
/// Records are kept as their JSON rows, so this reference persists exactly the
/// wire form the model round-trips. Nothing here is durable, indexed or
/// thread-safe: it is the smallest backend that satisfies the contract.
class InMemoryManufacturerRepository
    with InMemoryRowSourceBy<Manufacturer>
    implements IManufacturerRepository {
  /// Creates an empty [InMemoryManufacturerRepository].
  InMemoryManufacturerRepository()
    : table = InMemoryTable<Manufacturer>(
        decode: Manufacturer.fromJson,
        encode: (manufacturer) => manufacturer.toJson(),
        idOf: (manufacturer) => manufacturer.meta.id,
      );

  /// The rows behind this repository — what a transaction snapshots.
  @override
  final InMemoryTable<Manufacturer> table;

  @override
  TaskEither<DomainFailure, List<Manufacturer>> fetchAll() =>
      TaskEither.of(table.all());

  @override
  TaskEither<DomainFailure, Manufacturer> fetchById({required String id}) {
    final found = table.find(id);
    if (found == null) {
      return TaskEither<DomainFailure, Manufacturer>.left(
        NotFoundFailure('Manufacturer "$id" not found'),
      );
    }
    return TaskEither.of(found);
  }

  @override
  TaskEither<DomainFailure, Manufacturer> create({
    required Manufacturer manufacturer,
  }) {
    if (table.has(manufacturer.meta.id)) {
      return TaskEither<DomainFailure, Manufacturer>.left(
        AlreadyExistsFailure(
          'Manufacturer "${manufacturer.meta.id}" already exists',
        ),
      );
    }
    table.put(manufacturer);
    return TaskEither.of(manufacturer);
  }

  @override
  TaskEither<DomainFailure, Manufacturer> update({
    required Manufacturer manufacturer,
  }) {
    if (!table.has(manufacturer.meta.id)) {
      return TaskEither<DomainFailure, Manufacturer>.left(
        NotFoundFailure('Manufacturer "${manufacturer.meta.id}" not found'),
      );
    }
    table.put(manufacturer);
    return TaskEither.of(manufacturer);
  }

  @override
  TaskEither<DomainFailure, void> delete({required String id}) {
    if (!table.remove(id)) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('Manufacturer "$id" not found'),
      );
    }
    return TaskEither.of(null);
  }
}
