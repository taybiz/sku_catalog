import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'id_generator.dart';
import 'new_meta.dart';

/// Updates a SKU component's quantity.
///
/// The SKU-component contract has no update path, so the existing record is
/// deleted and re-created with the new quantity (a fresh id is assigned).
class UpdateSkuComponent {
  /// Creates an [UpdateSkuComponent] use case.
  const UpdateSkuComponent(this._repository, {this.idGenerator});

  final ISkuComponentRepository _repository;

  /// Mints the replacement's id; defaults to a random UUID v4 when null.
  final IdGenerator? idGenerator;

  /// Executes the use case.
  TaskEither<DomainFailure, SkuComponent> call({
    required String skuId,
    required int quantity,
  }) => _repository.fetchById(id: skuId).flatMap((current) {
    final replacement = SkuComponent(
      meta: newMeta(idGenerator: idGenerator),
      parentSkuId: current.parentSkuId,
      childSkuId: current.childSkuId,
      quantity: quantity,
    );
    return _repository.delete(id: skuId).flatMap((_) {
      return _repository.create(component: replacement);
    });
  });
}
