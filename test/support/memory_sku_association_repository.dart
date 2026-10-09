import 'package:sku_catalog/sku_catalog.dart';

import 'memory_unit_of_work.dart';
import 'package:fpdart/fpdart.dart';

/// In-memory [ISkuAssociationRepository] — test double backed by a [Map].
class MemorySkuAssociationRepository
    implements ISkuAssociationRepository, MemoryBacked {
  /// Creates an empty [MemorySkuAssociationRepository].
  MemorySkuAssociationRepository();

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
  TaskEither<DomainFailure, List<SkuAssociation>> fetchAll() =>
      TaskEither.of(_store.values.map(SkuAssociation.fromJson).toList());

  @override
  TaskEither<DomainFailure, List<SkuAssociation>> fetchBySku({
    required String skuId,
    String? kind,
  }) => TaskEither.of(
    _store.values
        .map(SkuAssociation.fromJson)
        .where(
          (a) =>
              (a.sourceSkuId == skuId || a.targetSkuId == skuId) &&
              (kind == null || a.kind == kind),
        )
        .toList(),
  );

  @override
  TaskEither<DomainFailure, SkuAssociation> fetchById({required String id}) {
    final record = _store[id];
    if (record == null) {
      return TaskEither<DomainFailure, SkuAssociation>.left(
        NotFoundFailure('SkuAssociation "$id" not found'),
      );
    }
    return TaskEither.of(SkuAssociation.fromJson(record));
  }

  @override
  TaskEither<DomainFailure, SkuAssociation> create({
    required SkuAssociation association,
    IUnitOfWork? uow,
  }) {
    _store[association.meta.id] = association.toJson();
    return TaskEither.of(association);
  }

  @override
  TaskEither<DomainFailure, void> delete({
    required String id,
    IUnitOfWork? uow,
  }) {
    if (_store.remove(id) == null) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('SkuAssociation "$id" not found'),
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
