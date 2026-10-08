import 'package:sku_catalog/sku_catalog.dart';

import 'memory_unit_of_work.dart';
import 'package:fpdart/fpdart.dart';

/// In-memory [ISkuRepository] — canonical test double backed by a [Map].
class MemorySkuRepository implements ISkuRepository, MemoryBacked {
  /// Creates an empty [MemorySkuRepository].
  MemorySkuRepository();

  final Map<String, Map<String, dynamic>> _store = {};
  @override
  Map<String, Map<String, dynamic>> get rows => _store;

  @override
  void replaceAll(Map<String, Map<String, dynamic>> rows) {
    _store
      ..clear()
      ..addAll(rows);
  }

  @override
  TaskEither<DomainFailure, List<Sku>> fetchAll() =>
      TaskEither.of(_store.values.map(Sku.fromJson).toList());

  @override
  TaskEither<DomainFailure, Sku> fetchById({required String id}) {
    final record = _store[id];
    if (record == null) {
      return TaskEither<DomainFailure, Sku>.left(
        NotFoundFailure('Sku "$id" not found'),
      );
    }
    return TaskEither.of(Sku.fromJson(record));
  }

  @override
  TaskEither<DomainFailure, Sku> create({required Sku sku, IUnitOfWork? uow}) {
    _store[sku.meta.id] = sku.toJson();
    return TaskEither.of(sku);
  }

  @override
  TaskEither<DomainFailure, Sku> update({required Sku sku, IUnitOfWork? uow}) {
    if (!_store.containsKey(sku.meta.id)) {
      return TaskEither<DomainFailure, Sku>.left(
        NotFoundFailure('Sku "${sku.meta.id}" not found'),
      );
    }
    _store[sku.meta.id] = sku.toJson();
    return TaskEither.of(sku);
  }

  @override
  TaskEither<DomainFailure, void> delete({
    required String id,
    IUnitOfWork? uow,
  }) {
    if (_store.remove(id) == null) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('Sku "$id" not found'),
      );
    }
    return TaskEither.of(null);
  }

  @override
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow}) {
    _store.clear();
    return TaskEither.of(null);
  }
}
