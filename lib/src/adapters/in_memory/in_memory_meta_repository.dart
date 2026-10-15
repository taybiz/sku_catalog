import 'package:fpdart/fpdart.dart';

import '../../domain/domain.dart';
import 'in_memory_table.dart';

/// An in-memory [IMetaRepository] — the catalog's own single record.
///
/// This one is not a table of records: the catalog has exactly one [`Meta`], so
/// the store keeps one row under the fixed key `meta`. It still presents that row
/// as [rows] so a transaction can snapshot it like every other store.
class InMemoryMetaRepository implements IMetaRepository, InMemoryRowSource {
  /// Creates an empty [InMemoryMetaRepository].
  InMemoryMetaRepository();

  static const Meta _empty = Meta(
    id: '',
    notes: '',
    createdAt: '',
    updatedAt: '',
  );

  static const String _rowKey = 'meta';

  Map<String, dynamic>? _record;

  /// The single record as one row, keyed [`_rowKey`].
  @override
  Map<String, Map<String, dynamic>> get rows =>
      _record == null ? const {} : {_rowKey: _record!};

  /// A copy of the single row — what a transaction keeps to undo itself.
  @override
  Map<String, Map<String, dynamic>> snapshot() => {
    for (final entry in rows.entries)
      entry.key: Map<String, dynamic>.from(entry.value),
  };

  /// Puts the single row back — how a rollback restores a snapshot.
  @override
  void replaceAll(Map<String, Map<String, dynamic>> rows) =>
      _record = rows[_rowKey];

  @override
  TaskEither<DomainFailure, Meta> fetch() =>
      TaskEither.of(_record == null ? _empty : Meta.fromJson(_record!));

  @override
  TaskEither<DomainFailure, Meta> update({
    required Meta meta,
    IUnitOfWork? uow,
  }) {
    _record = meta.toJson();
    return TaskEither.of(meta);
  }

  @override
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow}) {
    _record = null;
    return TaskEither.of(null);
  }
}
