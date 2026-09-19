import 'package:sku_catalog/sku_catalog.dart';
import 'package:fpdart/fpdart.dart';

/// In-memory [ISkuComponentRepository] — canonical test double backed by a [Map].
class MemorySkuComponentRepository implements ISkuComponentRepository {
  /// Creates an empty [MemorySkuComponentRepository].
  MemorySkuComponentRepository();

  final Map<String, Map<String, dynamic>> _store = {};

  @override
  TaskEither<DomainFailure, List<SkuComponent>> fetchAll() =>
      TaskEither.of(_store.values.map(SkuComponent.fromJson).toList());

  @override
  TaskEither<DomainFailure, List<SkuComponent>> fetchByDeviceType(
    String deviceTypeId,
  ) => TaskEither.of(
    _store.values
        .map(SkuComponent.fromJson)
        .where((c) => c.parentDeviceTypeId == deviceTypeId)
        .toList(),
  );

  @override
  TaskEither<DomainFailure, SkuComponent> fetchById(String id) {
    final record = _store[id];
    if (record == null) {
      return TaskEither<DomainFailure, SkuComponent>.left(
        NotFoundFailure('SkuComponent "$id" not found'),
      );
    }
    return TaskEither.of(SkuComponent.fromJson(record));
  }

  @override
  TaskEither<DomainFailure, SkuComponent> create(
    SkuComponent component, {
    IUnitOfWork? uow,
  }) {
    _store[component.meta.id] = component.toJson();
    return TaskEither.of(component);
  }

  @override
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow}) {
    if (_store.remove(id) == null) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('SkuComponent "$id" not found'),
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
