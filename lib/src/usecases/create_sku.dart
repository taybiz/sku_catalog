import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Create a new SKU.
class CreateSku {
  /// Creates a [CreateSku] use case.
  const CreateSku(this._repository);

  final ISkuRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Sku> call(Sku sku) => _repository.create(sku);
}
