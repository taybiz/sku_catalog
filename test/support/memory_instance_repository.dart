import 'package:sku_catalog/sku_catalog.dart';

import 'memory_unit_of_work.dart';
import 'package:fpdart/fpdart.dart';

/// In-memory [IInstanceRepository] — canonical test double backed by a [Map].
class MemoryInstanceRepository implements IInstanceRepository, MemoryBacked {
  /// Creates an empty [MemoryInstanceRepository].
  MemoryInstanceRepository();

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
  TaskEither<DomainFailure, List<Instance>> fetchAll() =>
      TaskEither.of(_store.values.map(Instance.fromJson).toList());

  @override
  TaskEither<DomainFailure, List<Instance>> fetchByLocate({
    required String locateId,
  }) => TaskEither.of(
    _store.values
        .map(Instance.fromJson)
        .where((d) => d.locateId == locateId)
        .toList(),
  );

  @override
  TaskEither<DomainFailure, Instance> fetchById({required String id}) {
    final record = _store[id];
    if (record == null) {
      return TaskEither<DomainFailure, Instance>.left(
        NotFoundFailure('Instance "$id" not found'),
      );
    }
    return TaskEither.of(Instance.fromJson(record));
  }

  @override
  TaskEither<DomainFailure, Instance> create({
    required Instance instance,
    IUnitOfWork? uow,
  }) {
    _store[instance.meta.id] = instance.toJson();
    return TaskEither.of(instance);
  }

  @override
  TaskEither<DomainFailure, Instance> update({
    required Instance instance,
    IUnitOfWork? uow,
  }) {
    if (!_store.containsKey(instance.meta.id)) {
      return TaskEither<DomainFailure, Instance>.left(
        NotFoundFailure('Instance "${instance.meta.id}" not found'),
      );
    }
    _store[instance.meta.id] = instance.toJson();
    return TaskEither.of(instance);
  }

  @override
  TaskEither<DomainFailure, void> delete({
    required String id,
    IUnitOfWork? uow,
  }) {
    if (_store.remove(id) == null) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('Instance "$id" not found'),
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
