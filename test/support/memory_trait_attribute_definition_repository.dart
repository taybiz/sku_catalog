import 'package:fpdart/fpdart.dart';
import 'package:sku_catalog/sku_catalog.dart';

import 'memory_unit_of_work.dart';

/// In-memory [ITraitAttributeDefinitionRepository] — canonical test double
/// backed by a [Map].
class MemoryTraitAttributeDefinitionRepository
    implements ITraitAttributeDefinitionRepository, MemoryBacked {
  /// Creates an empty [MemoryTraitAttributeDefinitionRepository].
  MemoryTraitAttributeDefinitionRepository();

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
  TaskEither<DomainFailure, List<TraitAttributeDefinition>> fetchAll() =>
      TaskEither.of(
        _store.values.map(TraitAttributeDefinition.fromJson).toList(),
      );

  @override
  TaskEither<DomainFailure, List<TraitAttributeDefinition>> fetchByTrait(
    String traitId,
  ) => TaskEither.of(
    _store.values
        .map(TraitAttributeDefinition.fromJson)
        .where((a) => a.traitId == traitId)
        .toList(),
  );

  @override
  TaskEither<DomainFailure, TraitAttributeDefinition> fetchById(String id) {
    final record = _store[id];
    if (record == null) {
      return TaskEither<DomainFailure, TraitAttributeDefinition>.left(
        NotFoundFailure('TraitAttributeDefinition "$id" not found'),
      );
    }
    return TaskEither.of(TraitAttributeDefinition.fromJson(record));
  }

  @override
  TaskEither<DomainFailure, TraitAttributeDefinition> create(
    TraitAttributeDefinition attribute, {
    IUnitOfWork? uow,
  }) {
    _store[attribute.meta.id] = attribute.toJson();
    return TaskEither.of(attribute);
  }

  @override
  TaskEither<DomainFailure, TraitAttributeDefinition> update(
    TraitAttributeDefinition attribute, {
    IUnitOfWork? uow,
  }) {
    if (!_store.containsKey(attribute.meta.id)) {
      return TaskEither<DomainFailure, TraitAttributeDefinition>.left(
        NotFoundFailure(
          'TraitAttributeDefinition "${attribute.meta.id}" not found',
        ),
      );
    }
    _store[attribute.meta.id] = attribute.toJson();
    return TaskEither.of(attribute);
  }

  @override
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow}) {
    if (_store.remove(id) == null) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('TraitAttributeDefinition "$id" not found'),
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
