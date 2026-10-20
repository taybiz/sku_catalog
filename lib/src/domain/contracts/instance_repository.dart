import 'package:fpdart/fpdart.dart';

import '../entities/instance.dart';
import '../failures/catalog_failures.dart';

/// Contract for instance persistence.
abstract interface class IInstanceRepository {
  /// Fetch all instances.
  TaskEither<DomainFailure, List<Instance>> fetchAll();

  /// Fetch instances belonging to a locate; `null` is the unplaced group.
  ///
  /// Every article sits at a place or at no place, and the unplaced group is a
  /// group: a store indexes a null like any other value.
  TaskEither<DomainFailure, List<Instance>> fetchByLocate({
    required String? locateId,
  });

  /// Fetch the instances of one model.
  TaskEither<DomainFailure, List<Instance>> fetchBySku({required String skuId});

  /// Fetch a single instance by id.
  TaskEither<DomainFailure, Instance> fetchById({required String id});

  /// Create a new instance.
  TaskEither<DomainFailure, Instance> create({required Instance instance});

  /// Update an existing instance.
  TaskEither<DomainFailure, Instance> update({required Instance instance});

  /// Delete an instance by id.
  TaskEither<DomainFailure, void> delete({required String id});
}
