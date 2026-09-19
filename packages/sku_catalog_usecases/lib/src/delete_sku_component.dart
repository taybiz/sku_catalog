import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Delete a SKU component by id.
class DeleteSkuComponent {
  /// Creates a [DeleteSkuComponent] use case.
  const DeleteSkuComponent(this._repository);

  final ISkuComponentRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call(String id) => _repository.delete(id);
}
