import 'package:fpdart/fpdart.dart';

import '../entities/trait_attribute_definition.dart';
import '../failures/catalog_failures.dart';
import 'unit_of_work.dart';

/// Contract for trait attribute definition persistence.
abstract interface class ITraitAttributeDefinitionRepository {
  /// Fetch all trait attribute definitions.
  TaskEither<DomainFailure, List<TraitAttributeDefinition>> fetchAll();

  /// Fetch attribute definitions for given trait.
  TaskEither<DomainFailure, List<TraitAttributeDefinition>> fetchByTrait(
    String traitId,
  );

  /// Fetch a single attribute definition by id.
  TaskEither<DomainFailure, TraitAttributeDefinition> fetchById(String id);

  /// Create a new attribute definition.
  TaskEither<DomainFailure, TraitAttributeDefinition> create(
    TraitAttributeDefinition attribute, {
    IUnitOfWork? uow,
  });

  /// Update an existing attribute definition.
  TaskEither<DomainFailure, TraitAttributeDefinition> update(
    TraitAttributeDefinition attribute, {
    IUnitOfWork? uow,
  });

  /// Delete an attribute definition by id.
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow});

  /// Remove every record (factory reset support).
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow});
}
