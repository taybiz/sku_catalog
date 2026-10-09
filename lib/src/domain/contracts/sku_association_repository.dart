import 'package:fpdart/fpdart.dart';

import '../entities/sku_association.dart';
import '../failures/catalog_failures.dart';
import 'unit_of_work.dart';

/// Contract for SKU association persistence.
abstract interface class ISkuAssociationRepository {
  /// Fetch all SKU associations.
  TaskEither<DomainFailure, List<SkuAssociation>> fetchAll();

  /// Associations whose source or target is [skuId]; when [kind] is non-null,
  /// only those carrying that role label.
  TaskEither<DomainFailure, List<SkuAssociation>> fetchBySku({
    required String skuId,
    String? kind,
  });

  /// Fetch a single association by id.
  TaskEither<DomainFailure, SkuAssociation> fetchById({required String id});

  /// Create a new SKU association.
  TaskEither<DomainFailure, SkuAssociation> create({
    required SkuAssociation association,
    IUnitOfWork? uow,
  });

  /// Delete a SKU association by id.
  TaskEither<DomainFailure, void> delete({
    required String id,
    IUnitOfWork? uow,
  });

  /// Remove every record (factory reset support).
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow});
}
