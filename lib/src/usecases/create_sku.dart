import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'assert_unique_model_number.dart';

/// Create a new SKU.
///
/// A model number is the manufacturer's production number, so two models from one
/// maker cannot share it — the rule is a create's to keep, not the backend's.
/// [AssertUniqueModelNumber] holds it; a caller builds one and shares it with the
/// update path.
class CreateSku {
  /// Creates a [CreateSku] use case.
  const CreateSku({
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
      ).flatMap((_) => _repository.create(sku: sku));
}
