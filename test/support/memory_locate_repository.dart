import 'package:sku_catalog/sku_catalog.dart';

import 'memory_unit_of_work.dart';
import 'package:fpdart/fpdart.dart';

/// In-memory [ILocateRepository] — canonical test double backed by a [Map].
class MemoryLocateRepository implements ILocateRepository, MemoryBacked {
  /// Creates an empty [MemoryLocateRepository].
  MemoryLocateRepository();

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
  TaskEither<DomainFailure, List<Locate>> fetchAll() =>
      TaskEither.of(_store.values.map(Locate.fromJson).toList());

  @override
  TaskEither<DomainFailure, Locate> fetchById(String id) {
    final record = _store[id];
    if (record == null) {
      return TaskEither<DomainFailure, Locate>.left(
        NotFoundFailure('Locate "$id" not found'),
      );
    }
    return TaskEither.of(Locate.fromJson(record));
  }

  @override
  TaskEither<DomainFailure, Locate> create(Locate locate, {IUnitOfWork? uow}) {
    _store[locate.meta.id] = locate.toJson();
    return TaskEither.of(locate);
  }

  @override
  TaskEither<DomainFailure, Locate> update(Locate locate, {IUnitOfWork? uow}) {
    if (!_store.containsKey(locate.meta.id)) {
      return TaskEither<DomainFailure, Locate>.left(
        NotFoundFailure('Locate "${locate.meta.id}" not found'),
      );
    }
    _store[locate.meta.id] = locate.toJson();
    return TaskEither.of(locate);
  }

  @override
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow}) {
    if (_store.remove(id) == null) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('Locate "$id" not found'),
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
