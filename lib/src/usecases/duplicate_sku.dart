import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'new_meta.dart';

/// Duplicates a SKU: fresh meta and a "(copy)" model number.
class DuplicateSku {
  /// Creates a [DuplicateSku] use case.
  const DuplicateSku(this._skuRepository);

  final ISkuRepository _skuRepository;

  /// Executes the use case.
  TaskEither<DomainFailure, Sku> call(String id) =>
      _skuRepository.fetchById(id).flatMap((current) {
        final copy = current.copyWith(
          meta: newMeta(),
          modelNumber: '${current.modelNumber} (copy)',
        );
        return _skuRepository.create(copy);
      });
}
