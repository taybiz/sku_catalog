import 'package:fpdart/fpdart.dart';
import 'package:sku_catalog/sku_catalog.dart';

/// A memory-backed store whose rows a [MemoryUnitOfWork] can snapshot and put
/// back. Implemented by every repository in this package.
abstract interface class MemoryBacked {
  /// The backing rows, keyed by record id.
  Map<String, Map<String, dynamic>> get rows;

  /// Replaces every row — how a rollback restores a snapshot.
  void replaceAll(Map<String, Map<String, dynamic>> rows);
}

/// A real unit of work over this package's stores: the rows of every registered
/// store are snapshotted before the body runs, and put back when the body
/// returns a `Left`.
///
/// This is what makes an atomic multi-write operation testable without a
/// database — pair it with the use cases that accept one:
///
/// ```dart
/// final uow = MemoryUnitOfWork([skus, edges]);
/// final result = await uow.runEither(body: () async {
///   await deleteAnEdge().run();     // if this returns Left ...
///   return deleteTheSku().run();    // ... this never happens, and the edge is back
/// });
/// ```
///
/// Register the stores the operation will touch; a store that is not registered
/// is not rolled back.
class MemoryUnitOfWork implements IUnitOfWork {
  /// Creates a unit of work over [stores].
  MemoryUnitOfWork(Iterable<MemoryBacked> stores)
    : _stores = List<MemoryBacked>.unmodifiable(stores);

  final List<MemoryBacked> _stores;

  @override
  Future<Either<F, T>> runEither<F, T>({
    required Future<Either<F, T>> Function() body,
  }) async {
    final snapshots = <MemoryBacked, Map<String, Map<String, dynamic>>>{
      for (final store in _stores)
        store: {
          for (final entry in store.rows.entries)
            entry.key: Map<String, dynamic>.from(entry.value),
        },
    };
    final result = await body();
    if (result.isLeft()) {
      for (final entry in snapshots.entries) {
        entry.key.replaceAll(entry.value);
      }
    }
    return result;
  }
}
