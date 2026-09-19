import 'package:sku_catalog_domain/sku_catalog_domain.dart';

import 'memory_unit_of_work.dart';
import 'package:fpdart/fpdart.dart';

/// In-memory [ITraitRepository] — canonical test double backed by a [Map].
class MemoryTraitRepository implements ITraitRepository, MemoryBacked {
  /// Creates an empty [MemoryTraitRepository].
  MemoryTraitRepository();

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
  TaskEither<DomainFailure, List<Trait>> fetchAll() =>
      TaskEither.of(_store.values.map(Trait.fromJson).toList());

  @override
  TaskEither<DomainFailure, Trait> fetchById(String id) {
    final record = _store[id];
    if (record == null) {
      return TaskEither<DomainFailure, Trait>.left(
        NotFoundFailure('Trait "$id" not found'),
      );
    }
    return TaskEither.of(Trait.fromJson(record));
  }

  @override
  TaskEither<DomainFailure, Trait> create(Trait trait, {IUnitOfWork? uow}) {
    _store[trait.meta.id] = trait.toJson();
    return TaskEither.of(trait);
  }

  @override
  TaskEither<DomainFailure, Trait> update(Trait trait, {IUnitOfWork? uow}) {
    if (!_store.containsKey(trait.meta.id)) {
      return TaskEither<DomainFailure, Trait>.left(
        NotFoundFailure('Trait "${trait.meta.id}" not found'),
      );
    }
    _store[trait.meta.id] = trait.toJson();
    return TaskEither.of(trait);
  }

  @override
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow}) {
    if (_store.remove(id) == null) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('Trait "$id" not found'),
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
