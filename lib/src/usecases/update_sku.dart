import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Update an existing SKU.
class UpdateSku {
  /// Creates an [UpdateSku] use case.
  const UpdateSku(this._repository);

  final ISkuRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Sku> call({required Sku sku}) =>
      _repository.update(sku: sku);
}
