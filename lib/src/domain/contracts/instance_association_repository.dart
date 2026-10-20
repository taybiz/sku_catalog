import 'package:fpdart/fpdart.dart';

import '../entities/instance_association.dart';
import '../failures/catalog_failures.dart';

/// Contract for article-to-article association persistence.
abstract interface class IInstanceAssociationRepository {
  /// Fetch all instance associations.
  TaskEither<DomainFailure, List<InstanceAssociation>> fetchAll();

  /// Associations whose source or target is [instanceId]; when [kind] is
  /// non-null, only those carrying that role label.
  TaskEither<DomainFailure, List<InstanceAssociation>> fetchByInstance({
    required String instanceId,
    String? kind,
  });

  /// Fetch a single association by id.
  TaskEither<DomainFailure, InstanceAssociation> fetchById({
    required String id,
  });

  /// Create a new instance association.
  TaskEither<DomainFailure, InstanceAssociation> create({
    required InstanceAssociation association,
  });

  /// Delete an instance association by id.
  TaskEither<DomainFailure, void> delete({required String id});
}
