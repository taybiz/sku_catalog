import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'assert_unique_model_number.dart';

/// Update an existing SKU.
///
/// The model-number rule applies here as it does on the create path, with the
/// model's own id excluded so an edit that keeps its number is not a clash with
/// itself.
class UpdateSku {
  /// Creates an [UpdateSku] use case.
  const UpdateSku({
    required ISkuRepository skuRepository,
    required AssertUniqueModelNumber assertUniqueModelNumber,
  }) : _repository = skuRepository,
       _assertUniqueModelNumber = assertUniqueModelNumber;

  final ISkuRepository _repository;
  final AssertUniqueModelNumber _assertUniqueModelNumber;

  /// Executes the use case.
  TaskEither<DomainFailure, Sku> call({required Sku sku}) =>
      _assertUniqueModelNumber(
        modelNumber: sku.modelNumber,
        manufacturerId: sku.manufacturerId,
        excludeId: sku.meta.id,
      ).flatMap((_) => _repository.update(sku: sku));
}
