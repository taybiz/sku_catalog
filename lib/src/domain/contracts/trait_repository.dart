import 'package:fpdart/fpdart.dart';

import '../entities/trait.dart';
import '../failures/catalog_failures.dart';

/// Contract for trait persistence.
abstract interface class ITraitRepository {
  /// Fetch all traits.
  TaskEither<DomainFailure, List<Trait>> fetchAll();

  /// Fetch a single trait by id.
  TaskEither<DomainFailure, Trait> fetchById({required String id});

  /// Create a new trait.
  TaskEither<DomainFailure, Trait> create({required Trait trait});

  /// Update an existing trait.
  TaskEither<DomainFailure, Trait> update({required Trait trait});

  /// Delete a trait by id.
  TaskEither<DomainFailure, void> delete({required String id});
}
