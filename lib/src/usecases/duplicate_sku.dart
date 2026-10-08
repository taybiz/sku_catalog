import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'id_generator.dart';
import 'new_meta.dart';

/// Duplicates a SKU: fresh meta and a "(copy)" model number.
class DuplicateSku {
  /// Creates a [DuplicateSku] use case.
  const DuplicateSku(this._skuRepository, {this.idGenerator});

  final ISkuRepository _skuRepository;

  /// Mints the copy's id; defaults to a random UUID v4 when null.
  final IdGenerator? idGenerator;

  /// Executes the use case.
  TaskEither<DomainFailure, Sku> call({required String id}) =>
      _skuRepository.fetchById(id: id).flatMap((current) {
        final copy = current.copyWith(
          meta: newMeta(idGenerator: idGenerator),
          modelNumber: '${current.modelNumber} (copy)',
        );
        return _skuRepository.create(sku: copy);
      });
}
