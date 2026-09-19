import 'package:sku_catalog_domain/sku_catalog_domain.dart';

import 'memory_unit_of_work.dart';
import 'package:fpdart/fpdart.dart';

/// In-memory [IDeviceRepository] — canonical test double backed by a [Map].
class MemoryDeviceRepository implements IDeviceRepository, MemoryBacked {
  /// Creates an empty [MemoryDeviceRepository].
  MemoryDeviceRepository();

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
  TaskEither<DomainFailure, List<Device>> fetchAll() =>
      TaskEither.of(_store.values.map(Device.fromJson).toList());

  @override
  TaskEither<DomainFailure, List<Device>> fetchByLocate(String locateId) =>
      TaskEither.of(
        _store.values
            .map(Device.fromJson)
            .where((d) => d.locateId == locateId)
            .toList(),
      );

  @override
  TaskEither<DomainFailure, Device> fetchById(String id) {
    final record = _store[id];
    if (record == null) {
      return TaskEither<DomainFailure, Device>.left(
        NotFoundFailure('Device "$id" not found'),
      );
    }
    return TaskEither.of(Device.fromJson(record));
  }

  @override
  TaskEither<DomainFailure, Device> create(Device device, {IUnitOfWork? uow}) {
    _store[device.meta.id] = device.toJson();
    return TaskEither.of(device);
  }

  @override
  TaskEither<DomainFailure, Device> update(Device device, {IUnitOfWork? uow}) {
    if (!_store.containsKey(device.meta.id)) {
      return TaskEither<DomainFailure, Device>.left(
        NotFoundFailure('Device "${device.meta.id}" not found'),
      );
    }
    _store[device.meta.id] = device.toJson();
    return TaskEither.of(device);
  }

  @override
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow}) {
    if (_store.remove(id) == null) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('Device "$id" not found'),
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
