import 'package:sku_catalog/sku_catalog.dart';
import 'package:fpdart/fpdart.dart';

/// In-memory [IMetaRepository] — canonical test double holding one record.
class MemoryMetaRepository implements IMetaRepository {
  /// Creates an empty [MemoryMetaRepository].
  MemoryMetaRepository();

  static const Meta _empty = Meta(
    id: '',
    notes: '',
    createdAt: '',
    updatedAt: '',
  );

  Map<String, dynamic>? _record;

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
