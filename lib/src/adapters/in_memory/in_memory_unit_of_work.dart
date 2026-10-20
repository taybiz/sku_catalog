import 'package:fpdart/fpdart.dart';

import '../../domain/domain.dart';
import 'in_memory_table.dart';

/// A real transaction over in-memory tables, as a [UnitOfWork]: every table it
/// was built over is snapshotted before the body runs and put back when the body
/// answers `Left`.
///
/// This is what makes a multi-write use case atomic without a database — pair it
/// with `DeleteSku` or `DeleteInstance`. Register every table the operation
/// touches; a table that is not registered is not rolled back. [InMemoryCatalog]
/// hands you one built over all of its tables, which is the way to not have to
/// remember.
///
/// Nothing here is durable and nothing is locked: it is the smallest thing that
/// makes a two-write operation testable, and the shape a real adapter replaces.
UnitOfWork inMemoryUnitOfWork(Iterable<InMemoryRowSource> tables) {
  final registered = List<InMemoryRowSource>.unmodifiable(tables);
  return <F, T>({required Future<Either<F, T>> Function() body}) async {
    final snapshots = <InMemoryRowSource, Map<String, Map<String, dynamic>>>{
      for (final table in registered) table: table.snapshot(),
    };
    final result = await body();
    if (result.isLeft()) {
      for (final entry in snapshots.entries) {
        entry.key.replaceAll(entry.value);
      }
    }
    return result;
  };
}
