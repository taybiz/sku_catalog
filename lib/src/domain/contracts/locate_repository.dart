import 'package:fpdart/fpdart.dart';

import '../entities/locate.dart';
import '../failures/catalog_failures.dart';

/// Contract for locate persistence.
abstract interface class ILocateRepository {
  /// Fetch all locates.
  TaskEither<DomainFailure, List<Locate>> fetchAll();

  /// Fetch a single locate by id.
  TaskEither<DomainFailure, Locate> fetchById({required String id});

  /// Create a new locate.
  TaskEither<DomainFailure, Locate> create({required Locate locate});

  /// Update an existing locate.
  TaskEither<DomainFailure, Locate> update({required Locate locate});

  /// Delete a locate by id.
  TaskEither<DomainFailure, void> delete({required String id});
}
