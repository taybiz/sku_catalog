import 'package:sku_catalog_domain/sku_catalog_domain.dart';

import 'memory_unit_of_work.dart';
import 'package:fpdart/fpdart.dart';

/// In-memory [IManufacturerRepository] — canonical test double backed by a [Map].
class MemoryManufacturerRepository
    implements IManufacturerRepository, MemoryBacked {
  /// Creates an empty [MemoryManufacturerRepository].
  MemoryManufacturerRepository();

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
  TaskEither<DomainFailure, List<Manufacturer>> fetchAll() =>
      TaskEither.of(_store.values.map(Manufacturer.fromJson).toList());

  @override
  TaskEither<DomainFailure, Manufacturer> fetchById(String id) {
    final record = _store[id];
    if (record == null) {
      return TaskEither<DomainFailure, Manufacturer>.left(
        NotFoundFailure('Manufacturer "$id" not found'),
      );
    }
    return TaskEither.of(Manufacturer.fromJson(record));
  }

  @override
  TaskEither<DomainFailure, Manufacturer> create(
    Manufacturer manufacturer, {
    IUnitOfWork? uow,
  }) {
    _store[manufacturer.meta.id] = manufacturer.toJson();
    return TaskEither.of(manufacturer);
  }

  @override
  TaskEither<DomainFailure, Manufacturer> update(
    Manufacturer manufacturer, {
    IUnitOfWork? uow,
  }) {
    if (!_store.containsKey(manufacturer.meta.id)) {
      return TaskEither<DomainFailure, Manufacturer>.left(
        NotFoundFailure('Manufacturer "${manufacturer.meta.id}" not found'),
      );
    }
    _store[manufacturer.meta.id] = manufacturer.toJson();
    return TaskEither.of(manufacturer);
  }

  @override
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow}) {
    if (_store.remove(id) == null) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('Manufacturer "$id" not found'),
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
