import 'package:sku_catalog/sku_catalog.dart';

import 'memory_unit_of_work.dart';
import 'package:fpdart/fpdart.dart';

/// In-memory [IMetaRepository] — canonical test double holding one record.
class MemoryMetaRepository implements IMetaRepository, MemoryBacked {
  /// Creates an empty [MemoryMetaRepository].
  MemoryMetaRepository();

  static const Meta _empty = Meta(
    id: '',
    notes: '',
    createdAt: '',
    updatedAt: '',
  );

  Map<String, dynamic>? _record;

  /// The single record, presented as one row so a [MemoryUnitOfWork] can
  /// snapshot it like any other store.
  @override
  Map<String, Map<String, dynamic>> get rows =>
      _record == null ? const {} : {'meta': _record!};

  @override
  void replaceAll(Map<String, Map<String, dynamic>> rows) {
    _record = rows['meta'];
  }

  @override
  TaskEither<DomainFailure, Meta> fetch() =>
      TaskEither.of(_record == null ? _empty : Meta.fromJson(_record!));

  @override
  TaskEither<DomainFailure, Meta> update(Meta meta, {IUnitOfWork? uow}) {
    _record = meta.toJson();
    return TaskEither.of(meta);
  }

  @override
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow}) {
    _record = null;
    return TaskEither.of(null);
  }
}
