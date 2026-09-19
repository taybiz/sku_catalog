import 'package:sku_catalog/sku_catalog.dart';
import 'package:fpdart/fpdart.dart';

/// In-memory [IDeviceTypeRepository] — canonical test double backed by a [Map].
class MemoryDeviceTypeRepository implements IDeviceTypeRepository {
  /// Creates an empty [MemoryDeviceTypeRepository].
  MemoryDeviceTypeRepository();

  final Map<String, Map<String, dynamic>> _store = {};

  @override
  TaskEither<DomainFailure, List<DeviceType>> fetchAll() =>
      TaskEither.of(_store.values.map(DeviceType.fromJson).toList());

  @override
  TaskEither<DomainFailure, DeviceType> fetchById(String id) {
    final record = _store[id];
    if (record == null) {
      return TaskEither<DomainFailure, DeviceType>.left(
        NotFoundFailure('DeviceType "$id" not found'),
      );
    }
    return TaskEither.of(DeviceType.fromJson(record));
  }

  @override
  TaskEither<DomainFailure, DeviceType> create(
    DeviceType deviceType, {
    IUnitOfWork? uow,
  }) {
    _store[deviceType.meta.id] = deviceType.toJson();
    return TaskEither.of(deviceType);
  }

  @override
  TaskEither<DomainFailure, DeviceType> update(
    DeviceType deviceType, {
    IUnitOfWork? uow,
  }) {
    if (!_store.containsKey(deviceType.meta.id)) {
      return TaskEither<DomainFailure, DeviceType>.left(
        NotFoundFailure('DeviceType "${deviceType.meta.id}" not found'),
      );
    }
    _store[deviceType.meta.id] = deviceType.toJson();
    return TaskEither.of(deviceType);
  }

  @override
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow}) {
    if (_store.remove(id) == null) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('DeviceType "$id" not found'),
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
