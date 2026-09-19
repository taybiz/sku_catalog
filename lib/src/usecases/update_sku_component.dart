import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'new_meta.dart';

/// Updates a SKU component's quantity.
///
/// The SKU-component contract has no update path, so the existing record is
/// deleted and re-created with the new quantity (a fresh id is assigned).
class UpdateSkuComponent {
  /// Creates an [UpdateSkuComponent] use case.
  const UpdateSkuComponent(this._repository);

  final ISkuComponentRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, SkuComponent> call(String skuId, int quantity) =>
      _repository.fetchById(skuId).flatMap((current) {
        final replacement = SkuComponent(
          meta: newMeta(),
          parentDeviceTypeId: current.parentDeviceTypeId,
          childDeviceTypeId: current.childDeviceTypeId,
          quantity: quantity,
        );
        return _repository.delete(skuId).flatMap((_) {
          return _repository.create(replacement);
        });
      });
}
