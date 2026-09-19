import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Create a new SKU component.
class CreateSkuComponent {
  /// Creates a [CreateSkuComponent] use case.
  const CreateSkuComponent(this._repository);

  final ISkuComponentRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, SkuComponent> call(SkuComponent component) =>
      _repository.create(component);
}
