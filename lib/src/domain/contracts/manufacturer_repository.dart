import 'package:fpdart/fpdart.dart';

import '../entities/manufacturer.dart';
import '../failures/catalog_failures.dart';

/// Contract for manufacturer persistence.
abstract interface class IManufacturerRepository {
  /// Fetch all manufacturers.
  TaskEither<DomainFailure, List<Manufacturer>> fetchAll();

  /// Fetch a single manufacturer by id.
  TaskEither<DomainFailure, Manufacturer> fetchById({required String id});

  /// Create a new manufacturer.
  TaskEither<DomainFailure, Manufacturer> create({
    required Manufacturer manufacturer,
  });

  /// Update an existing manufacturer.
  TaskEither<DomainFailure, Manufacturer> update({
    required Manufacturer manufacturer,
  });

  /// Delete a manufacturer by id.
  TaskEither<DomainFailure, void> delete({required String id});
}
